class AddReputationColumnsToCle < ActiveRecord::Migration[5.2]
  def change
    add_column :challenge_leaderboard_extras, :weight, :float, default: 0.005
    add_column :challenge_leaderboard_extras, :sub_round_size, :integer, default: 1
    add_column :challenge_leaderboard_extras, :use_for_final_rating, :boolean, default: false
    add_column :challenge_leaderboard_extras, :use_for_weekly_rating, :boolean, default: false
    add_column :challenge_leaderboard_extras, :rank_last_calculated_at, :datetime
    add_column :challenge_leaderboard_extras, :rating_calculated, :boolean, default: false
  end
end
