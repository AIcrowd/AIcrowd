module Reputation
  class RatingCalculationJob < ApplicationJob
    queue_as :default

    def perform
      challenge_leaderboard_extras = ChallengeLeaderboardExtra.where(ranking_enabled: true, rating_calculated: false).order(:created_at).includes(:challenge_round)
      challenge_leaderboard_extras.each do |cle|
        if cle.rank_last_calculated_at + 7.days == Date.today || (cle.rank_last_calculated_at.blank? && cle.start_dttm + 7.days == Date.today)
          if cle.challenge_round.end_dttm < DateTime.now + 7.days
            continue
          else
            if cle.use_for_weekly_rating?
              Reputation::RatingService.new(cle.id).call
            end
          end
        end
        if cle.challenge_round.end_dttm > DateTime.now
          if cle.use_for_final_rating?
            Reputation::RatingService.new(cle.id).call
          end
        end
      end
    end
  end
end
