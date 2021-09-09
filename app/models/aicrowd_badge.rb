class AicrowdBadge < ApplicationRecord
  has_paper_trail
  has_many :aicrowd_user_badges
  belongs_to :badge_type
  belongs_to :badges_event
  # mount_uploader :image, LogoImageUploader
  # validates :name, uniqueness: true, presence: true
  def badges_event_name
    BadgesEvent.find_by(id:self.badges_event_id)&.name
  end

end
