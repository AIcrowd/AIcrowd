class AddMixpanelSentToSubmissions < ActiveRecord::Migration[5.2]
  def change
    add_column :submissions, :mixpanel_sent, :boolean, default: false
  end
end
