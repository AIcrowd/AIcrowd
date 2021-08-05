class Rating < ApplicationRecord
  belongs_to :challenge_leaderboard_extra
  has_one :global_rank
end
