class AddNewColumnsToAicrowdBadges < ActiveRecord::Migration[5.2]
  def change
     add_column :aicrowd_badges, :level, :integer
     add_column :aicrowd_badges, :target, :integer
     add_column :aicrowd_badges, :social_message, :text
     remove_index :aicrowd_badges, name: "index_aicrowd_badges_on_name"
  end
end
