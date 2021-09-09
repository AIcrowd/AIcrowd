class ReputationChangeObserver
  def update(changed_data)

    return if changed_data[:merit_object].is_a?(Merit::Score::Point)

    description = changed_data[:description]

    # If user is your meritable model, you can query for it doing:
    participant = Participant.where(sash_id: changed_data[:sash_id]).first
    aicrowd_badge = AicrowdBadge.find changed_data[:merit_object][:badge_id]

    custom_fields = {}
    AicrowdUserBadge.create!(aicrowd_badge_id: aicrowd_badge.id, participant_id: participant.id, custom_fields: custom_fields)

    NotificationService.new(participant.id, aicrowd_badge, 'badge').call


    # When did it happened:
    datetime = changed_data[:granted_at]
  end
end