class RatingsController < ApplicationController

  def index
    @rank_1 = GlobalRank.order('rating desc').first
    @rank_2 = GlobalRank.order('rating desc').second
    @rank_3 = GlobalRank.order('rating desc').third

    @rankings = GlobalRank.order('rating desc').includes(:participant).offset(3).limit(100)
    get_topper_graph_data
    get_topper_rank_change
  end

  def create
    ratings = Rating.create!(rating_params["_json"])
    cle = ratings.first.challenge_leaderboard_extra
    if cle.use_for_final_rating?
      cle.rating_calculated = true
    end
    cle.rank_last_calculated_at = DateTime.now
    cle.save!
    # Reputation::CalculateGlobalRankJob.perform_later(ratings)

    # Now send notifications - Challenge end notification
    #
  end

  def search
    participant_ids = Participant.where('name ILIKE ? OR first_name ILIKE ? OR city ILIKE ? OR affiliation ILIKE ?', "%#{params[:q]}%", "%#{params[:q]}%", "%#{params[:q]}%", "%#{params[:q]}%").pluck(:id)
    country_code = ISO3166::Country.find_country_by_name(params[:q])&.map(&:alpha2)
    participant_ids + Participant.where(country_cd: country_code).pluck(:id)
    @rankings = GlobalRank.order('rating desc').where(participant_id: participant_ids).includes(:participant).limit(100)
  end

  private

  def rating_params
    params.permit!
  end

  def get_topper_graph_data
    @rank_1_graph = {}
    @rank_2_graph = {}
    @rank_3_graph = {}
    @rank_1.participant.ratings.order('created_at desc').limit(5).each do |rating|
      @rank_1_graph[rating.created_at.to_date] = rating.rating
    end
    @rank_2.participant.ratings.order('created_at desc').limit(5).each do |rating|
      @rank_2_graph[rating.created_at.to_date] = rating.rating
    end
    @rank_3.participant.ratings.order('created_at desc').limit(5).each do |rating|
      @rank_3_graph[rating.created_at.to_date] = rating.rating
    end
  end

  def get_topper_rank_change
    @rank_1_change = "+0"
    @rank_2_change = "+0"
    @rank_3_change = "+0"
    if @rank_1.participant.ratings.count > 1
      rank_1_ratings = @rank_1.participant.ratings.order('created_at desc').limit(2)
      change = rank_1_ratings.first.rating - rank_1_ratings.second.rating
      @rank_1_change = change >= 0 ? "+#{change}" : "#{change}"
    end

    if @rank_2.participant.ratings.count > 1
      rank_2_ratings = @rank_2.participant.ratings.order('created_at desc').limit(2)
      change = rank_2_ratings.first.rating - rank_2_ratings.second.rating
      @rank_2_change = change >= 0 ? "+#{change}" : "#{change}"
    end

    if @rank_3.participant.ratings.count > 1
      rank_3_ratings = @rank_3.participant.ratings.order('created_at desc').limit(2)
      change = rank_3_ratings.first.rating - rank_3_ratings.second.rating
      @rank_3_change = change >= 0 ? "+#{change}" : "#{change}"
    end
  end




end