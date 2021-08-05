class Participant < ApplicationRecord
  include FriendlyId
  include ApiKey
  include Countries

  GDPR_FIELDS = [
    :id,
    :email,
    :created_at,
    :updated_at,
    :timezone,
    :name,
    :bio,
    :website,
    :github,
    :linkedin,
    :twitter,
    :image_file,
    :affiliation,
    :country_cd,
    :address,
    :first_name,
    :last_name
  ].freeze

  friendly_id :name, use: [:slugged, :finders]

  before_save :set_api_key
  before_save { self.email = email.downcase }
  before_save :process_urls
  after_create :set_email_preferences
  after_save :publish_to_prometheus
  after_commit :upsert_discourse_user, on: [:create, :update]
  after_commit :update_gitlab_user, on: [:update, :create]

  mount_uploader :image_file, ImageUploader
  validates :image_file, file_size: { less_than: 5.megabytes }

  devise :confirmable,
         :database_authenticatable,
         :lockable,
         :recoverable,
         :registerable,
         :rememberable,
         :validatable,
         :omniauthable, omniauth_providers: %i[github oauth2_generic google_oauth2]

  acts_as_commontator

  default_scope { order('participants.name ASC') }

  scope :rated_users_count, -> { Participant.where("ranking > 0").count }
  scope :admins, -> { where(admin: true) }
  scope :with_every_email_preference, -> { joins(:email_preferences).where(email_preferences: { email_frequency_cd: :every }) }

  belongs_to :referred_by, class_name: 'Participant', optional: true

  has_many :referrals, class_name: 'Participant', foreign_key: :referred_by_id, dependent: :nullify
  has_many :aicrowd_user_badges, dependent: :destroy
  has_many :participant_organizers, dependent: :destroy
  has_many :organizers, through: :participant_organizers, dependent: :destroy
  has_many :submissions, dependent: :nullify
  has_many :votes, dependent: :destroy
  has_many :user_ratings, dependent: :destroy
  has_many :blogs, dependent: :nullify
  has_many :challenge_participants, dependent: :destroy
  has_many :leaderboards, class_name: 'Leaderboard', as: :submitter
  has_many :ongoing_leaderboards, class_name: 'OngoingLeaderboard', as: :submitter
  has_many :base_leaderboards, as: :submitter, dependent: :nullify
  has_many :participant_challenges,
           class_name: 'ParticipantChallenge',
           dependent: :destroy
  has_many :challenge_registrations,
           class_name: 'ChallengeRegistration',
           dependent: :destroy
  has_many :participant_challenge_counts,
           class_name: 'ParticipantChallengeCount',
           dependent: :destroy
  has_many :challenges,
           through: :challenge_participants
  has_many :dataset_file_downloads,
           dependent: :destroy
  has_many :task_dataset_file_downloads,
           dependent: :destroy
  has_many :email_preferences,
           dependent: :destroy
  has_many :email_preferences_tokens,
           dependent: :destroy
  has_many :follows, as: :followable, dependent: :destroy
  has_many :following,
           foreign_key: :participant_id,
           class_name: "Follow",
           dependent: :destroy
  has_many :participant_clef_tasks,
           dependent: :destroy
  has_many :invitations, dependent: :destroy
  has_many :access_grants,
           class_name:  "Doorkeeper::AccessGrant",
           foreign_key: :resource_owner_id,
           dependent:   :destroy
  has_many :access_tokens,
           class_name:  "Doorkeeper::AccessToken",
           foreign_key: :resource_owner_id,
           dependent:   :destroy

  has_many :visits, class_name: "Ahoy::Visit", foreign_key: :user_id
  has_many :team_participants, inverse_of: :participant, dependent: :destroy
  has_many :teams, through: :team_participants, inverse_of: :participants
  has_many :concrete_teams, -> { concrete }, through: :team_participants, source: :team, inverse_of: :participants
  has_many :invitor_team_invitations, class_name: 'TeamInvitation', foreign_key: :invitor_id, inverse_of: :invitor, dependent: :destroy
  has_many :invitee_team_invitations, class_name: 'TeamInvitation', foreign_key: :invitee_id, inverse_of: :invitee_participant, foreign_type: 'Participant', dependent: :destroy
  has_many :invitor_email_invitations, class_name: 'EmailInvitation', foreign_key: :invitor_id, inverse_of: :invitor, dependent: :nullify
  has_many :claimant_email_invitations, class_name: 'EmailInvitation', foreign_key: :claimant_id, dependent: :nullify
  has_many :newsletter_emails, class_name: 'NewsletterEmail', dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_many :team_members, dependent: :destroy
  has_many :participant_ml_challenge_goals, dependent: :destroy
  has_many :ml_activity_points
  has_many :posts
  has_many :ratings
  has_many :ml_activity_points, dependent: :destroy
  # has_many :likes, dependent: :destroy
  has_many :posts, dependent: :nullify

  validates :email,
            presence:              true,
            'valid_email_2/email': true,
            uniqueness:            { case_sensitive: false }

  validates :website, url: { allow_blank: true }
  validates :github, url: { allow_blank: true }
  validates :linkedin, url: { allow_blank: true }
  validates :twitter, url: { allow_blank: true }
  validates :name,
            format:     {
              with:    /\A(?=.*[a-zA-Z])[a-zA-Z0-9.\-_{}\[\]]+\z/,
              message: 'username can contain numbers and these characters -_.{}[] and atleast one letter'
            },
            length:     { in: 2...50 },
            uniqueness: { case_sensitive: false }
  validates :affiliation,
            length:      { in: 2...100 },
            allow_blank: true
  validates :country_cd,
            inclusion: { in: ISO3166::Country.codes }, allow_blank: true
  validates :address,
            length:      { in: 10...255 },
            allow_blank: true
  validates :first_name,
            length:      { in: 2...100 },
            allow_blank: true
  validates :last_name,
            length:      { in: 2...100 },
            allow_blank: true
  validates :uuid, uniqueness: true

  after_update do
    ParticipantBadgeJob.perform_later(name: "profileupdate", participant_id: id)
  end

  def self.api_admin
    @@api_admin ||= find_by(email: ENV['AICROWD_API_EMAIL'])
  end

  # Send reconfirmation e-mail after e-mail change only in production
  def reconfirmation_required?
    # TODO: Remove ENV['IS_REAL_PRODUCTION'] == 'true' after we update staging config
    return super if Rails.env.production? && ENV['IS_REAL_PRODUCTION'] == 'true'

    false
  end

  def reserved_userhandle
    return unless name

    errors.add(:name, 'is reserved for CrowdAI users.  Please log in via CrowdAI to claim this user handle.') if (provider != 'crowdai') && ReservedUserhandle.where(name: name.downcase).exists?
  end

  def disable_account(reason)
    update(
      account_disabled:        true,
      account_disabled_reason: reason,
      account_disabled_dttm:   Time.now)
  end

  def enable_account
    update(
      account_disabled:        false,
      account_disabled_reason: nil,
      account_disabled_dttm:   nil)
  end

  def datetime_sequence(start, stop, step)
    dates = [start]
    while dates.last < (stop - step)
      dates << (dates.last + step)
    end
    return dates
  end
  def add_badge(name, custom_fields={})
    badge_id = AicrowdBadge.find_by(name: name).id
    AicrowdUserBadge.create!(aicrowd_badge_id: badge_id, participant_id: id, custom_fields: custom_fields)
  end

  def rm_badge(name)
    badge_id = AicrowdBadge.find_by(name: name).id
    AicrowdUserBadge.find_by(aicrowd_badges_id: badge_id, participant_id: id).destroy
  end

  def badges
    aicrowd_user_badges
  end
  def user_rating_history
    user_rating = UserRating.joins("left outer join challenge_rounds on (challenge_rounds.id=challenge_round_id)").joins("left outer join challenges c on (c.id=challenge_rounds.challenge_id)").where(participant_id: self.id).where('rating is not null').reorder('user_ratings.created_at::date + user_ratings.updated_at::time, user_ratings.id').pluck('user_ratings.created_at::date + user_ratings.updated_at::time', 'rating - 3 * variation as final_rating',  'concat(challenge, challenge_round)')
    final_ratings = []
    user_rating.each_with_index do |rating, index|
      current_rating = user_rating[index]
      final_ratings << current_rating
      if index > 0
        date_sequences = datetime_sequence(user_rating[index - 1][0], user_rating[index][0], 1.day)
        date_sequences = date_sequences.slice(1, date_sequences.size - 2)
        for day in date_sequences.to_a
          time_difference = day.to_date - user_rating[index - 1][0].to_date
          time_difference = time_difference.to_i
          factor_of_decay = 4
          total_number_of_days = factor_of_decay*365
          updated_rating = user_rating[index - 1][1] * (Math.exp(-time_difference.to_f/total_number_of_days.to_f))
          final_ratings << [day, updated_rating, '']
        end
      end
    end
    return final_ratings
  end
  def final_rating
    self.rating.to_i - 3*self.variation.to_i
  end

  def badges_stats
    badges_stat_count = badges.badges_stat_count
    bronze_badges = badges.individual_badges(BadgeType.bronze).select_display_fields.limit(5)
    silver_badges = badges.individual_badges(BadgeType.silver).select_display_fields.limit(5)
    gold_badges = badges.individual_badges(BadgeType.gold).select_display_fields.limit(5)
    badges = {Gold: gold_badges, Silver: silver_badges, Bronze: bronze_badges}
    return badges_stat_count, badges
  end
  def badges_tab_stats
    badges_summary = badges.badges_stat_count
    bronze_badges_stats = badges.individual_badges(BadgeType.bronze).group('aicrowd_badge_id').count
    silver_badges_stats = badges.individual_badges(BadgeType.bronze).group('aicrowd_badge_id').count
    gold_badges_stats = badges.individual_badges(BadgeType.bronze).group('aicrowd_badge_id').count
    other_badges_stats = badges.individual_badges(BadgeType.bronze).group('aicrowd_badge_id').count
    return badges_summary, bronze_badges_stats, silver_badges_stats, gold_badges_stats, other_badges_stats
  end

  def awaiting_toasts
    badges.joins('left outer join aicrowd_badges as ab on ab.id=aicrowd_badge_id').select('ab.name', 'ab.description').where(toast_shown: false)
  end

  def toggle_toasts
    badges.where(toast_shown: false).update_all(toast_shown: true)
  end

  def final_temporary_rating
    (self.temporary_rating || self.temporary_variation)? self.temporary_rating.to_i - 3*self.temporary_variation.to_i: self.rating.to_i - 3*self.variation.to_i
  end
  def active_for_authentication?
    super && account_disabled == false
  end

  def inactive_message
    'Your account has been disabled. Please contact us at help@aicrowd.com' if account_disabled
  end

  def user_type
    if admin?
      'Admin'
    elsif organizers.present?
      'Organizer'
    else
      'Participant'
    end
  end

  def admin?
    admin
  end

  def online?
    updated_at > 10.minutes.ago
  end

  def avatar
    image.try(:image)
  end

  def avatar_medium_url
    if image.present?
      image.image.url(:medium)
    else
      "//#{ENV['DOMAIN_NAME']}/assets/image_not_found.png"
    end
  end


  def image_url
    image_url = if image_file.file.present?
                  image_file.url
                else
                  get_default_image
                end
  end

  def get_default_image
    num = id % 8
    "users/AIcrowd-DarkerBG (#{num}).png"
  end

  def process_urls
    ['website', 'github', 'linkedin', 'twitter'].each do |url_field|
      format_url(url_field)
    end
  end

  def format_url(url_field)
    if send(url_field).present?
      send("#{url_field}=", "http://#{send(url_field)}") unless send(url_field).include?("http://") || send(url_field).include?("https://")
    end
  end

  def after_confirmation
    super
    AddToMailChimpListJob.perform_later(id)
    detect_country
  end

  def set_email_preferences
    email_preferences.create!
  end

  def should_generate_new_friendly_id?
    name_changed?
  end

  # TODO: Investigate how to get rid of this hack without causing issues
  def self.find(args)
    super
  rescue StandardError
    nil
  end

  def publish_to_prometheus
    Prometheus::ParticipantCounterService.new.call
  end

  def detect_country
    return if country_cd.present?

    detected_country = visits.where.not(country: nil)&.last&.country
    return unless detected_country.present?

    country_code = ISO3166::Country.all_names_with_codes.to_h[detected_country]
    update!(country_cd: country_code)
  end

  def current_participation_terms
    ParticipationTerms.current_terms
  end

  def current_participation_terms_version
    current_participation_terms&.version
  end

  def has_accepted_participation_terms?
    return if participation_terms_accepted_version != current_participation_terms_version
    return unless participation_terms_accepted_date

    return true
  end

  def challenge_submissions(challenge)
    Submission.participant_challenge_submissions(challenge.id, id)
  end

  def meta_challenge_submissions(challenge)
    Submission.participant_meta_challenge_submissions(challenge.id, id)
  end

  def followers_participant_count
    follows.participant_type.count
  end

  def following_participant_count
    following.participant_type.count
  end

  def following_participant?(p_id)
    following.participant_type.pluck(:followable_id).include?(p_id.to_i)
  end

  private

  def upsert_discourse_user
    return if Rails.env.development? || Rails.env.test?
    return unless saved_change_to_attribute?(:name) || saved_change_to_attribute?(:email)

    Discourse::UpsertUserJob.perform_later(self.id)
  end

  def update_gitlab_user
    return if Rails.env.development? || Rails.env.test?
    return unless saved_change_to_attribute?(:name)

    Gitlab::UpdateUsernameJob.perform_later(self.id)
  end
end
