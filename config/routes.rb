require 'sidekiq/web'
require 'sidekiq/cron/web'

def challenge_routes
  collection do
    get :reorder
    post :assign_order
  end

  member do
    get :remove_image
    get :remove_social_media_image
    get :remove_banner
    get :remove_banner_mobile
    get :clef_task
    get :export
    post :import
    get :remove_invited
    get :notebooks
    get :make_notebooks_public
  end

  resources :teams, only: [:create, :show], param: :name, constraints: { name: %r{[^?/]+} }, format: false, controller: 'challenges/teams' do
    resources :invitations, only: [:create], controller: 'challenges/team_invitations'
  end
  resources :dataset_files, except: [:show]
  resources :dataset_folders, only: [:new, :create, :edit, :update, :destroy]
  resources :participant_challenges, only: [:index]
  resources :events
  resources :winners, only: [:index]
  resources :submissions do
    post :filter, on: :collection
    get :export, on: :collection
    get :lock, on: :collection
    get :freezed_submission_export, on: :collection
    get :reset_locked_submissions, on: :collection
    post :freeze_submission, on: :collection
    get :reevaluate_submission, on: :collection
    get :mermaid_data, on: :collection
  end
  resources :dynamic_contents, only: [:index]
  resources :leaderboards, only: [:index, :destroy] do
    get :export, on: :collection
    get :get_affiliation, on: :collection
    get :recalculate_leaderboard
  end
  resources :votes, only: [:create, :destroy]
  resources :follows, only: [:create, :destroy]
  resources :invitations, only: [] do
    collection { post :import }
  end
  resources :dataset_terms, only: [:update]
  resources :participation_terms, only: [:show, :create, :index]
  resource :challenge_rules, only: [:show]
  resources :challenge_rules, only: [:show]
  resources :challenge_participants do
    get :export, on: :collection
  end
  resources :insights, only: [:index] do
    collection do
      get 'submissions_vs_time'
      get 'top_score_vs_time'
      get 'challenge_participants_country'
      get 'participant_count'
      get 'graded_vs_failed'
    end
  end
end

Rails.application.routes.draw do
  mount Ckeditor::Engine => '/ckeditor'
  mount Commontator::Engine => '/commontator'
  get '/robots.txt' => RobotsTxt
  use_doorkeeper

  get 'test_gauge', to: 'test#gauge'
  get 'sso', to: 'participants#sso'
  get 'leaderboard', to: 'rating_leaderboard#index'
  get 'round_leaderboard_ranks/:round_id', to: 'user_rating#get_leaderboard_ranks'
  post 'post_new_participant_ratings/:round_id', to: 'user_rating#post_new_participant_ratings'
  admin = lambda do |request|
    request.env['warden'].authenticate? && request.env['warden'].user.admin?
  end
  super_admin = lambda do |request|
    request.env['warden'].authenticate? && request.env['warden'].user.super_admin?
  end

  constraints super_admin do
    mount Blazer::Engine => '/blazer'
  end

  constraints admin do
    mount Sidekiq::Web => '/sidekiq'
    begin
      ActiveAdmin.routes(self)
    rescue StandardError
      ActiveAdmin::DatabaseHitDuringLoad
    end
    namespace :admin do
      resources :team_participants, only: []
      resources :challenges, only: [] do
        resources :teams, only: [], param: :name do
          resources :team_participants
          resources :team_invitations
        end
      end
      resources :challenge_calls, only: [] do
        put 'acknowledge', to: 'admin/challenge_calls#acknowledge', as: :acknowledge_by_person
      end
    end
  end

  namespace :api do
    namespace :v1 do
      resources :challenges, only: [:create, :update], module: :challenges do
        get :masthead, on: :member
        resources :challenge_rounds, only: [:create, :update, :destroy]
        resources :newsletter_emails, only: [] do
          get  :search, on: :collection
          post :preview, on: :collection
        end
        resources :dataset_files, only: [:create, :update, :destroy]
        resources :dataset_folders, only: [:create, :update, :destroy]
      end
      resources :organizers, only: [:show, :create, :update], module: :organizers do
        resources :participant_organizers, only: [:create, :destroy]
      end
      resources :participants, only: [] do
        get :user_profile, on: :member
        post :discourse_notifications, on: :collection
      end
      resources :newsletter_emails, only: [] do
        post :decline, on: :member
      end
      resources :feedbacks, only: :create
      resource :api_user, only: :show

      get 'check_login' => 'sessions/helpers#check_login', :as => :check_login
    end

    resources :external_graders, only: [:create, :show, :update] do
      get :challenge_config, on: :collection
      get :presign, on: :member
      get :submission_info, on: :member
    end

    resources :challenges, only: [:index, :show] do
      resources :submissions, only: :index
    end

    resources :clef_tasks, only: [:show]
    resources :participants, only: :show, constraints: { id: /.+/ }, format: false
    resources :submissions, only: [:index, :show]

    get 'old_submissions/:id' => 'old_submissions#show'
    get 'old_submissions' => 'old_submissions#index'

    get 'user', to: 'oauth_credentials#show'
    get 'mailchimps/webhook' => 'mailchimps#verify', :as => :verify_webhook
    post 'mailchimps/webhook' => 'mailchimps#webhook', :as => :update_webhook
  end

  namespace :components do
    resources :notifications, only: [:index]
  end

  devise_for :participants, controllers: {
    omniauth_callbacks: 'participants/omniauth_callbacks',
    registrations: 'participants/registrations',
    passwords: 'participants/passwords',
    unlocks: 'participants/unlocks',
    confirmations: 'participants/confirmations',
    sessions: 'participants/sessions'
  }

  resources :participants, only: [:show, :edit, :update, :destroy, :index], id: /[^\/]+/ do
    resources :follows, only: [:create, :destroy]
    get :sync_mailchimp
    get :regen_api_key
    get :remove_image
    get :notifications_message
    patch :accept_terms
    get :impersonate, on: :collection
    get :stop_impersonating, on: :collection
    get '/read_notification/:id' => 'participants#read_notification', :as => :read_notification
    match '/notifications', to: 'email_preferences#edit', via: :get
    match '/notifications', to: 'email_preferences#update', via: :patch
  end

  match '/api/v1/submissions', to: 'submissions#create', via: :post, defaults: { is_api_request: true }
  match '/api/v1/submissions', to: 'submissions#new_api', via: :get, defaults: { is_api_request: true }

  resources :job_postings, path: "jobs", only: [:index, :show]
  resources :gdpr_exports, only: [:create]
  resources :landing_page, only: [:index]
  match '/landing_page/host', to: 'landing_page#host', via: :get

  resources :organizer_applications, only: [:create]
  resources :organizers, except: [:new, :index] do
    get :remove_image
    get :regen_api_key
    get :clef_email
    resources :clef_tasks
    resources :members
  end
  resources :blogs, only: [:index, :show] do
    resources :votes, only: [:create, :destroy]
  end
  resources :comment, only: [:index, :show] do
    resources :votes, only: [:create, :destroy]
  end
  resources :commontator_comment, only: [:index, :show] do
    resources :votes, only: [:create, :destroy]
  end

  resources :teams, only: [:show], param: :name, constraints: { name: %r{[^?/]+} }, format: false # legacy
  resources :claim_emails, only: [:index, :create], controller: 'team_invitations/claim_emails'
  resources :team_invitations, only: [], param: :uuid do
    resources :acceptances, only: [:index, :create], controller: 'team_invitations/acceptances'
    resources :declinations, only: [:index, :create], controller: 'team_invitations/declinations'
    resources :cancellations, only: [:create], controller: 'team_invitations/cancellations'
  end

  resources :success_stories, only: [:index, :show]

  resources :clef_tasks do
    resources :task_dataset_files
  end

  resources :participant_clef_tasks

  resources :task_dataset_files do
    resources :task_dataset_file_downloads, only: :create
  end

  resources :participation_terms, only: [:index]

  match '/challenges/:id/problems', to: 'challenge_problems#show', via: [:get, :post]

  # TODO: Move below challenge routes into Challenges module
  resources :challenges, only: [:index, :show, :new, :create, :edit, :update] do
    challenge_routes
    resources :problems, only: [:show, :edit, :update], controller: 'challenges', key: :challenge do |problem|
      challenge_routes
    end
  end

  resources :challenges, only: [], module: :challenges do
    resource :discussion, only: :show
    resource :newsletter_emails, only: [:new, :create]

    resources :problems, only: :show do |problem|
      resource :discussion, only: :show
      resource :newsletter_emails, only: [:new, :create]
    end
  end

  get '/load_more_challenges', to: 'challenges#load_more', as: :load_more_challenges

  resources :dataset_files, only: [] do
    resources :dataset_file_downloads, only: [:create]
  end

  resources :team_members, path: "our_team", only: [:index]
  resources :practice, only: [:index]
  resources :posts, path: :showcase do
    resources :votes, only: [:create, :destroy]
    post :validate_colab_link, on: :collection
    post :validate_notebook, on: :collection
  end
  resources :publications, path: :research, only: [:index, :show] do
    get :all, on: :collection
  end
  resources :ratings, only: [:index, :create] do
    get :search, on: :collection
  end

  match '/contact', to: 'pages#contact', via: :get
  match '/privacy', to: 'pages#privacy', via: :get
  match '/terms',   to: 'pages#terms',   via: :get
  match '/faq',     to: 'pages#faq',     via: :get
  match '/cookies', to: 'pages#cookies_info', via: :get
  match '/crowdai_migration', to: 'crowdai_migration#new', via: :get
  match '/crowdai_migration/save', to: 'crowdai_migration#create', via: :post

  # Custom Redirect
  get '/food', to: redirect('/challenges/food-recognition-challenge', status: 302)
  get '/derk', to: redirect('/challenges/dr-derk-s-battleground', status: 302)
  get '/flatland', to: redirect('/challenges/neurips-2020-flatland-challenge', status: 302)

  resources :markdown_editors, only: [:index, :create] do
    put :presign, on: :collection
  end

  resources :challenge_calls, only: [] do
    resources :challenge_call_responses, only: [:create]
  end
  resource :search, only: :show
  resources :daily_practice_goals, only: [:index]
  resources :participant_ml_challenge_goals, only: [:create, :update]
  resources :baselines, only: [:index]

  get '/call-for-challenges/:challenge_call_id/apply' => 'challenge_call_responses#new', :as => 'challenge_call_apply'
  get '/call-for-challenges/:challenge_call_id/applications/:id' => 'challenge_call_responses#show', :as => 'challenge_call_show'
  get 'SDSC' => 'challenge_call_responses#new', :challenge_call_id => 3

  ['400', '403', '404', '422', '500'].each do |code|
    get code, controller: :errors, action: :show, code: code
  end

  root 'landing_page#index'

  # catch all
  get '*short', to: 'short_urls#show'
end
