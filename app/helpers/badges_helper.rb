module BadgesHelper
  def active_badge(aicrowd_badges, participant = current_participant)
    points = participant.points(category: aicrowd_badges.first.name)

    aicrowd_badges.order(target: :desc).each do |badge|
      if points >= badge.target
        return badge
      end
    end
  end
end