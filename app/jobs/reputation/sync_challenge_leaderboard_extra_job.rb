module Reputation
  class SyncChallengeLeaderboardExtraJob < ApplicationJob
    queue_as :default

    def perform
      # Reputation::SyncChallengeLeaderbaordExtraService.new.call
    end
  end
end
