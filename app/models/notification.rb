class Notification < ApplicationRecord
  belongs_to :participant
  belongs_to :notifiable, polymorphic: true, optional: true
  belongs_to :challenge, optional: true

  default_scope { order(created_at: :desc) }

  scope :pristine, -> { where(is_new: true) }
  scope :recent, -> { order(created_at: :desc) }
  scope :unread, -> { where(read_at: nil) }

  validates :notification_type, presence: true

  after_commit :invalidate_cache

  NOTIFICATION_TYPE = {
    'Mention'        => :mention,
    'Graded'         => :graded,
    'Grading Failed' => :grading_failed,
    'Leaderboard'    => :leaderboard,
    'Article'        => :article,
    'Discourse'      => :discourse,
    'Badge'          => :badge
  }.freeze

  def read?
    read_at.present?
  end

  def invalidate_cache
    Rails.cache.delete("participant_notifications_#{self.participant_id}")
  end
end
