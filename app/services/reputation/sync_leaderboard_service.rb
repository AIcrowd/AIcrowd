module Reputation
  class SyncLeaderboardService

    def initialize cle_id
      @cle_id = cle_id
    end

    def call
      # last_updated_time = get_last_updated_time
      sync_data
    end

    def get_synced_leaderboard_extras
      response = HTTP.get("#{ENV['RATING_SANDBOX_URL']}/contest/challenge_leaderboard_extras", headers: {Authorization: "Bearer #{secure_data}"})
      return JSON.parse(response.body)
    end

    def get_last_updated_time
      response = HTTP.get("#{ENV['RATING_SANDBOX_URL']}/standing/get_update_time", headers: {Authorization: "Bearer #{secure_data}"})
      standing = JSON.parse(response.body)
      standing["created_at"]
    end

    def secure_data
      payload = {fastapi: "aicrowd", access_key: "aicrowd_reputation_system"}
      JWT.encode(payload, ENV['REPUTATION_TOKEN'])
    end

    def sync_data
      # challenge_leaderboard_extra_ids = get_synced_leaderboard_extras
      base_leaderboards = BaseLeaderboard.where(leaderboard_type_cd: "leaderboard", challenge_leaderboard_extra_id: @cle_id)
      result = []
      base_leaderboards.each do |bl|
        if true
          if bl.challenge_round_id && bl.row_num && bl.created_at && bl.submitter_id
            if bl.submitter_type == "Team"
              TeamParticipant.where(team_id: bl.submitter_id).each do |tp|
                result << {challenge_leaderboard_extra_id: bl.challenge_leaderboard_extra_id, rank: bl.row_num - 1, created_at: bl.created_at, participant_id: tp.participant_id}
              end
            else
              result << {challenge_leaderboard_extra_id: bl.challenge_leaderboard_extra_id, rank: bl.row_num - 1, created_at: bl.created_at, participant_id: bl.submitter_id}
            end
          end
        end
      end
      response = HTTP.post("#{ENV['RATING_SANDBOX_URL']}/standing/create", json: result, headers: {Authorization: "Bearer #{secure_data}"})
    end
  end
end