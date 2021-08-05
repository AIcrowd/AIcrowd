module Reputation
  class CalculateGlobalRankService
    def initialize(ratings)
      @ratings = ratings
    end

    def call
      update_rating_ids
      update_rank
    end

    def update_rating_ids
      @ratings.each do |rating|
        global_rank = GlobalRank.where(participant_id: rating.participant_id).first_or_initialize
        global_rank.rating_id = rating.id
        global_rank.rating = rating.rating
        global_rank.save!
      end
    end

    def update_rank
      ActiveRecord::Base.transaction do
        sql = "select rating_id, RANK () OVER (ORDER BY rating desc) FROM global_ranks"
        rating_ranks = ActiveRecord::Base.connection.execute(sql)
        rating_ranks_hash = {}
        rating_ranks.values.each do |rating_rank|
          rating_ranks_hash[rating_rank[0]] = rating_rank[1]
        end
        GlobalRank.all.each do |gr|
          rating = gr.user_rating
          rating.rank = rating_ranks_hash[rating.id]
          rating.save!
        end
      end
    end
  end
end