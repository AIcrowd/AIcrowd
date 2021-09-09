class NotificationService
  include Rails.application.routes.url_helpers
  include ActionView::Helpers::AssetTagHelper

  def initialize(participant_id, notifiable, notification_type)
    @participant       = Participant.find(participant_id)
    @notifiable        = notifiable
    @notification_type = notification_type
  end

  def call
    send(@notification_type) if ['graded', 'failed', 'leaderboard', 'badge'].include?(@notification_type)
  end

  private

  def graded
    score   = submission_score || 0.0
    message = "Your #{@notifiable.challenge.challenge} Challenge submission ##{@notifiable.id} has been graded with a score of #{score}"
    thumb   = @notifiable.challenge.image_file.url
    link    = challenge_submission_url(@notifiable.challenge, @notifiable.id)

    existing_notification = @participant.notifications.where(notifiable: @notifiable).first

    return if existing_notification.present?

    Notification
      .create!(
        participant:       @participant,
        notifiable:        @notifiable,
        notification_type: @notification_type,
        message:           message,
        thumbnail_url:     thumb,
        notification_url:  link,
        challenge_id:      @notifiable.challenge.id,
        is_new:            true)
  end

  def failed
    message = "Your #{@notifiable.challenge.challenge} Challenge submission ##{@notifiable.id} failed to evaluate."
    thumb   = @notifiable.challenge.image_file.url
    link    = challenge_submission_url(@notifiable.challenge, @notifiable.id)

    existing_notification = @participant.notifications.where(notifiable: @notifiable).first

    return if existing_notification.present?

    Notification
      .create!(
        participant:       @participant,
        notifiable:        @notifiable,
        notification_type: @notification_type,
        message:           message,
        thumbnail_url:     thumb,
        notification_url:  link,
        challenge_id:      @notifiable.challenge.id,
        is_new:            true)
  end

  def leaderboard
    return unless @notifiable.show_leaderboard?

    return if @participant.nil?

    # get similar unread notification of challenge
    existing_notification = @participant.notifications.where(notification_type: 'leaderboard', challenge_id: @notifiable.challenge.id, is_new: true)
    existing_notification.delete_all # delete old unread notification of this challenge

    last_notification = @participant.notifications.where(notification_type: 'leaderboard', challenge_id: @notifiable.challenge.id)&.first
    if last_notification.present?
      if last_notification.message.match(/from (?:.*) to (.*) place/).present?
        @notifiable.previous_row_num = last_notification.message.match(/from (?:.*) to (.*) place/).captures[0]
      elsif last_notification.message.match(/secured (.*) place/).present?
        @notifiable.previous_row_num = last_notification.message.match(/secured (.*) place/).captures[0]
      end
    end

    return if last_notification.present? && @notifiable.previous_row_num == @notifiable.row_num

    message = unless last_notification.present?
                "Congratulations! You made your first submission and secured #{@notifiable.row_num&.ordinalize.to_s} place in the #{@notifiable.challenge.challenge} leaderboard."
              else
                "You have moved from #{@notifiable.previous_row_num&.ordinalize.to_s} to #{@notifiable.row_num&.ordinalize.to_s} place in the #{@notifiable.challenge.challenge} leaderboard."
              end

    return if @participant.notifications.exists?(notification_type: 'leaderboard', challenge_id: @notifiable.challenge.id, message: message)

    thumb   = @notifiable.challenge.image_file.url
    link    = challenge_leaderboards_url(@notifiable.challenge)

    # create new notification for this challenge
    Notification
      .create!(
        participant:       @participant,
        notifiable:        @notifiable,
        notification_type: @notification_type,
        message:           message,
        thumbnail_url:     thumb,
        notification_url:  link,
        challenge_id:      @notifiable.challenge.id,
        is_new:            true)
  end

  def badge
    message = @notifiable.description
    thumb = @notifiable.image
    link = participant_path(@participant)

    return if @participant.notifications.exists?(notification_type: 'badge', message: message)

    Notification
      .create!(
        participant:       @participant,
        notifiable:        @notifiable,
        notification_type: @notification_type,
        message:           message,
        thumbnail_url:     thumb,
        notification_url:  link,
        is_new:            true)
  end

  def submission_score
    leaderboard = @notifiable.challenge_round.default_leaderboard
    if leaderboard.present? && leaderboard.dynamic_score_field.present?
      return @notifiable["meta"][leaderboard.dynamic_score_field].presence || 0.0
    end
    return @notifiable.score
  end
end
