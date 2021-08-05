class CreateGlobalRanks < ActiveRecord::Migration[5.2]
  def change
    create_table :global_ranks do |t|
      t.integer :participant_id
      t.integer :rating_id
      t.float   :rating

      t.timestamps
    end
  end
end
