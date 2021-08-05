class AddContestIdToRatings < ActiveRecord::Migration[5.2]
  def change
    add_column :ratings, :contest_id, :integer, null: false
  end
end
