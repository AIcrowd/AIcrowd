class AddRankingEnabledToChallengeLeaderboardExtras < ActiveRecord::Migration[5.2]
  def change
    add_column :challenge_leaderboard_extras, :ranking_enabled, :boolean, default: false
  end
end
