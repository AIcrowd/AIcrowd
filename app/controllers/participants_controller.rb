class ParticipantsController < ApplicationController
  before_action :authenticate_participant!, except: [:show, :index]
  before_action :set_participant,
                only: [:show, :edit, :update, :destroy, :set_follow]
  before_action :set_follow, only: [:show]
  before_action :check_super_admin, only: [:impersonate, :stop_impersonating]

  respond_to :html, :js

  def show
    @page_title   = @participant.name
    challenge_ids = policy_scope(ChallengeParticipant)
                    .where(participant_id: @participant.id)
                    .pluck(:challenge_id)

    @challenges = if policy(@participant).edit?
                    Challenge.where(id: challenge_ids)
                  else
                    Challenge.where(id: challenge_ids).where(hidden_challenge: false).where(private_challenge: false)
                  end

    @discourse_posts_fetch = Rails.cache.fetch("discourse-user-posts/#{@participant.id}", expires_in: 5.minutes) do
                               Discourse::FetchUserPostsService.new(participant: @participant).call
                             end
    @discourse_posts = @discourse_posts_fetch.value

    @activity_data = Participants::ActivityHeatmapService.new(participant: @participant).call.value

    @categories = @participant.challenges.joins(:categories).group('categories.name').reorder('categories.name').count
    if @categories.count == 0
      @categories = {'No category information' => 1}
    end
    @achievements_count = 0
    @participant.aicrowd_user_badges.badges_stat_count.map { |badge_type_id, badge_type_count| @achievements_count += badge_type_count if [1,2,3].include?(badge_type_id) }
  end

  def edit; end

  def index
    redirect_to root_path
  end

  def update
    @participant = Participant.friendly.find(params[:id])
    @participant.assign_attributes(participant_params)

    validate_name_length

    if @participant.errors.none? && @participant.save
      flash[:success] = "Profile updated"
      Mixpanel::SyncJob.perform_later(@participant, request.remote_ip)
      redirect_to @participant
    else
      flash[:error] = @participant.errors.full_messages.to_sentence
      render :edit
    end
  end

  def accept_terms
    @participant                                   = Participant.friendly.find(params[:participant_id])
    @challenge                                     = Challenge.friendly.find(params[:challenge_id])
    @participant.participation_terms_accepted_date = Time.now
    if @participant.update(accept_terms_params)
      if !policy(@challenge).has_accepted_challenge_rules?
        redirect_to [@challenge, @challenge.current_challenge_rules]
      else
        redirect_to @challenge
      end
    end
  end

  def destroy
    @participant.destroy
    redirect_to '/', notice: 'Account was successfully deleted.'
  end

  def regen_api_key
    @participant = Participant.friendly.find(params[:participant_id])
    authorize @participant
    @participant.api_key = @participant.generate_api_key
    @participant.save!
    redirect_to participant_path(@participant), notice: 'API Key regenerated.'
  end

  def sso
    authorize current_user
    url = sso_helper
    redirect_to url
  end

  def sync_mailchimp
    @job = AddToMailChimpListJob.perform_later(params[:participant_id])
    render 'admin/participants/refresh_sync_mailchimp_job_status'
  end

  def remove_image
    @participant = Participant.friendly.find(params[:participant_id])
    authorize @participant
    @participant.remove_image_file!
    @participant.save
    redirect_to edit_participant_path(@participant),
                notice: 'Image removed.'
  end

  def notifications_message
    @notifications = current_user.notifications
  end

  def read_notification
    if request.xhr? # Its a JS request
      @notifications = current_user.notifications.unread
      @notifications.update_all(is_new: false)
    else
      @notification = current_user.notifications.find(params[:id])
      @notification.update!(is_new: false)
      redirect_to @notification.notification_url || root_url
    end
  end

  def impersonate
    participant = Participant.friendly.find(params[:format])
    impersonate_participant(participant)
    flash[:info] = 'Impersonation Started.'
    redirect_to root_path
  end

  def stop_impersonating
    stop_impersonating_participant
    flash[:info] = 'Impersonation Stopped.'
    redirect_to root_path
  end

  private

  def set_participant
    if params[:id].downcase == 'me'
      if current_participant.present?
        redirect_to current_participant and return
      else
        session['participant_return_to'] = request.original_fullpath
        redirect_to new_participant_session_path and return
      end
    end

    @participant = Participant.friendly.find_by_friendly_id(params[:id].downcase)
    authorize @participant
  end

  def set_follow
    @follow = @participant.follows.where(participant_id: current_participant.id).first if current_participant.present?
  end

  def accept_terms_params
    params.require(:participant).permit(
      :participation_terms_accepted_version
    )
  end

  def participant_params
    params
      .require(:participant)
      .permit(
        :email,
        :password,
        :password_confirmation,
        :phone_number,
        :name,
        :organizer_id,
        :email_public,
        :bio,
        :website,
        :github,
        :linkedin,
        :twitter,
        :image_file,
        :affiliation,
        :address,
        :city,
        :country_cd,
        :first_name,
        :last_name,
        # NATE: we might need to allow this if for some reason a user has been created without agreeing,
        # for example during the oauth flow
        # :agreed_to_terms_of_use_and_privacy,
        :agreed_to_marketing)
  end

  def sso_helper
    decoded        = Base64.decode64(params[:sso])
    decoded_hash   = Rack::Utils.parse_query(decoded)
    nonce          = decoded_hash['nonce']
    return_sso_url = decoded_hash['return_sso_url']
    sig            = params[:sig]
    signed         = OpenSSL::HMAC.hexdigest("sha256", ENV['SSO_SECRET'], params[:sso])
    raise "Incorrect SSO signature" if sig != signed

    avatar_url = ENV['DOMAIN_NAME'] + get_default_image
    avatar_url = current_user.image_file.url if current_user.image_file && !current_user.image_file.url.nil?

    response_params = {
      email:       current_user.email,
      admin:       current_user.admin,
      external_id: current_user.id,
      name:        current_user.name,
      username:    current_user.name,
      nonce:       nonce,
      avatar_url:  avatar_url
    }

    response_query         = response_params.to_query
    encoded_response_query = Base64.strict_encode64(response_query)
    response_sig           = OpenSSL::HMAC.hexdigest("sha256", ENV['SSO_SECRET'], encoded_response_query)

    url = File.join(return_sso_url, "?sso=#{CGI.escape(encoded_response_query)}&sig=#{response_sig}")
  end

  def get_default_image
    num = current_user.id % 8
    "/assets/users/AIcrowd-DarkerBG (#{num}).png"
  end

  def validate_name_length
    @participant.errors.add(:name, 'is too long (maxium is 20 characters)') if @participant.name.to_s.length > 20
  end

  def check_super_admin
    if !(true_participant.present? && true_participant.super_admin?)
      flash[:error] = "You're not authorized to perform this action."
      return redirect_to root_path
    end
  end
end
