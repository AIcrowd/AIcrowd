class CreateRatings < ActiveRecord::Migration[5.2]
  def change
    create_table :ratings do |t|
      t.integer :challenge_leaderboard_extra_id, null: false
      t.integer :participant_id, null: false
      t.float   :rating, null: false
      t.float   :mu
      t.float   :sigma
      t.integer :rank

      t.timestamps
    end
  end
end
