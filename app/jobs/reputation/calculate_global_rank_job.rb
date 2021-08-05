module Reputation
  class CalculateGlobalRankJob < ApplicationJob
    queue_as :default

    def perform ratings
      Reputation::CalculateGlobalRankService.new(ratings).call
    end
  end
end
