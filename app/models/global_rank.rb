class GlobalRank < ApplicationRecord
  belongs_to :participant
  belongs_to :user_rating, foreign_key: :rating_id, class_name: "Rating"
end
