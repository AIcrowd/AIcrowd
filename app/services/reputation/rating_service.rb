module Reputation
  class RatingService

    def initialize(challenge_leaderboard_extra_id)
      @challenge_leaderboard_extra_id = challenge_leaderboard_extra_id
    end

    def call
      sync_challenge_leaderboard_extra_data
      sync_leaderboard_data
      initiate_rating_for_leaderboard
    end

    def sync_challenge_leaderboard_extra_data
      # Reputation::SyncChallengeLeaderbaordExtraService.new.call
    end

    def sync_leaderboard_data
      # Reputation::SyncLeaderboardService.new.call
    end

    def initiate_rating_for_leaderboard
      response = HTTP.post("#{ENV['RATING_SANDBOX_URL']}/rate/contest/#{@challenge_leaderboard_extra_id}", body: {return_url: ENV['RATING_RETURN_URL']}.to_json, headers: {Authorization: "Bearer #{secure_data}"})
      return response.body
    end


    def secure_data
      payload = {fastapi: "aicrowd", access_key: "aicrowd_reputation_system"}
      JWT.encode(payload, ENV['REPUTATION_TOKEN'])
    end

  end
end