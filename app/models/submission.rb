class Submission < ApplicationRecord
  include Markdownable
  include FreezeRecord

  has_paper_trail

  before_validation :generate_short_url
  before_validation :kramdown_grading_message

  belongs_to :challenge, counter_cache: true
  belongs_to :meta_challenge, optional: true, class_name: 'Challenge'
  belongs_to :ml_challenge, optional: true, class_name: 'Challenge'
  belongs_to :participant, optional: true
  belongs_to :challenge_round, optional: true
  has_one :notebook, as: :notebookable

  with_options dependent: :destroy do
    has_many :submission_files
    has_many :submission_grades
  end
  accepts_nested_attributes_for :submission_files,
                                reject_if:     ->(f) { f[:submission_file_s3_key].blank? },
                                allow_destroy: true
  has_many :votes, as: :votable

  as_enum :grading_status,
          [:ready, :submitted, :initiated, :graded, :failed], map: :string

  validates :challenge_id, presence: true
  validates :grading_status, presence: true

  delegate :name, :email, to: :participant, allow_nil: true

  default_scope { where(deleted: false) }
  scope :group_by_created_at, -> { group_by_day(:created_at).count }
  scope :participant_challenge_submissions, ->(challenge_id, p_ids) { where(challenge_id: challenge_id, participant_id: p_ids) }
  scope :participant_meta_challenge_submissions, ->(meta_challenge_id, p_ids) { where(meta_challenge_id: meta_challenge_id, participant_id: p_ids) }
  after_create :invalidate_cache

  after_create do
    if challenge_round_id.blank?
      rnd = challenge
        .challenge_rounds
        .where(
          'start_dttm <= ? and end_dttm >= ?',
          created_at, created_at).first
      rnd = challenge.challenge_rounds.last if rnd.blank?
      if rnd.present? && rnd.end_dttm.present?
        update(challenge_round_id: rnd.id)
        update(post_challenge: true) if created_at > rnd.end_dttm
      else
        raise ChallengeRoundIDMissing
      end
    end
  end

  after_commit on: [:create, :update] do
    unless self.deleted?
      # !self.meta&.dig('final_avg') is added to prevent infinite loops in New Leaderboard Calculation
      if grading_status_cd == 'graded' && !meta&.dig('private_ignore-leaderboard-job-computation')
        Rails.logger.info "[Submission Model] Starting the Leaderboard Update Job! (onsave)"
        CalculateLeaderboardJob
          .perform_later(challenge_round_id: challenge_round_id)
      end
      Prometheus::SubmissionCounterService.new(submission_id: id).call
      if grading_status_cd == 'graded'
        ParticipantBadgeJob.perform_later(name: "onsubmission", submission_id: id, grading_status_cd: grading_status_cd)
      end
      Notification::SubmissionNotificationJob.perform_later(id)

      if grading_status_cd == 'graded' || grading_status_cd == 'failed'
        unless self.mixpanel_sent
          participant = self.participant
          Mixpanel::EventJob.perform_later(participant, "Submission Complete", {
            'Submission ID': self.id,
            'Participant ID': participant.present? ? participant.uuid : "",
            'Challenge': self.challenge.slug,
            'Grading Status': grading_status_cd
          })
          self.mixpanel_sent = true
          self.save
        end
      end
    end
  end

  after_commit :recalculate_lb_on_submission_deletion, on: [:update]

  after_commit :render_notebook_from_submission, on: [:create, :update]

  #TODO: Disabled badge awards
  #after_save :give_awarding_point

  after_destroy do
    CalculateLeaderboardJob
      .perform_later(challenge_round_id: challenge_round_id)
  end

  def team
    participant&.teams&.for_challenge(challenge)&.first
  end

  def ready?
    grading_status == :ready
  end

  def submitted?
    grading_status == :submitted
  end

  def graded?
    grading_status == :graded
  end

  def failed?
    grading_status == :failed
  end

  def initiated?
    grading_status == :initiated
  end

  def other_scores_array
    other_scores = []
    challenge.other_scores_fieldnames_array.each do |fname|
      if (meta&.is_a? Hash) && (meta&.key? fname)
        other_scores << (meta[fname].nil? ? 0.0 : meta[fname])
      end
    end
    # Always return an array of size 5
    other_scores + [0.0] * (5 - other_scores.size)
  end

  CLEF_RETRIEVAL_TYPES = {
    'Visual'                     => :visual,
    'Textual'                    => :textual,
    'Mixed (Textual and Visual)' => :mixed,
    'Not applicable'             => :not_applicable
  }.freeze

  CLEF_RUN_TYPES = {
    'Automatic'                          => :automatic,
    'Feedback or / and Human Assistance' => :feedback,
    'Manual'                             => :manual
  }.freeze

  def as_json(options = {})
    super(
      only:    [:id, :participant_id, :score, :score_secondary, :grading_status_cd, :grading_message, :post_challenge, :media_content_type, :created_at, :updated_at, :meta],
      include: { participant: { only: [:name] } }
    )
  end

  private

  def generate_short_url
    self.short_url = SecureRandom.uuid
  end

  def kramdown_grading_message
    if self.grading_message_changed?
      self.grading_message = Kramdown::Document.new(self.grading_message.to_s, { coderay_line_numbers: nil }).to_html.html_safe
    end
  end

  def give_awarding_point
    return unless ml_challenge.present?

    MlChallenge::AwardPointJob.perform_now(self, 'first_submission') if first_submission?
    MlChallenge::AwardPointJob.perform_now(self, 'submission_points')
    MlChallenge::AwardPointJob.perform_now(self, 'new_challenge_signup_participation') if graded?
    MlChallenge::AwardPointJob.perform_now(self, 'participated_into_editors_selected_challenge') if editors_challenge?
    MlChallenge::AwardScoreImprovedPointJob.perform_now(id, self.class.name, 'score_improved_over_5_times')
  end

  def first_submission?
    participant.submissions.where(challenge_id: challenge.id, challenge_round_id: challenge_round.id).count == 1
  end

  def editors_challenge?
    challenge.practice_flag && challenge.editors_selection
  end

  def render_notebook_from_submission
    return if Post.where(submission_id: self.id, private: true, title: "Solution for submission #{self.id}").exists?
    if self.meta.present? && self.meta["private_generate_notebook_section"].present? && self.meta["private_notebook_job_started"].nil?
      self.meta["private_notebook_job_started"] = true
      NotebookRenderingJob.perform_later(self.id)
    end
  end

  def invalidate_cache
    Rails.cache.delete("submitter-submissions-#{self.challenge.id}-#{self.participant_id}-Participant")
    team = participant.teams.where(challenge_id: self.challenge.id)&.first
    Rails.cache.delete("submitter-submissions-#{self.challenge.id}-#{team.id}-Team") if team.present?
  end

  def recalculate_lb_on_submission_deletion
    if self.deleted? && BaseLeaderboard.where(submission_id: self.id).exists?
      CalculateLeaderboardJob.perform_later(challenge_round_id: self.challenge_round_id)
    end
  end

  class ChallengeRoundIDMissing < StandardError
    def initialize(msg = 'No Challenge Round ID can be found for this submission')
      super
    end
  end
end
