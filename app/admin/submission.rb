ActiveAdmin.register Submission do
  belongs_to :challenge, parent_class: Challenge
  navigation_menu :challenge

  # sidebar "Submission versions", only: [:show, :edit] do
  #   ul do
  #     submission.versions.reverse.each do |version|
  #       li link_to "#{version.created_at}", admin_paper_trail_version_path(version)
  #     end
  #   end
  # end

  filter :id
  filter :participant_id
  filter :name
  filter :media_content_type
  filter :score
  filter :score_secondary
  filter :post_challenge
  filter :grading_status_cd
  filter :grading_message

  index do
    selectable_column
    column :id
    column :participant_id
    column 'Name', &:name
    column 'Email', &:email
    column :challenge_round_id
    column 'Round' do |submission| submission.challenge_round.challenge_round end
    column :score
    column :score_secondary
    column :grading_status_cd
    column :grading_message
    column :post_challenge
    column :media_content_type
    column :created_at
    column :updated_at
    actions
  end

  controller do
    def scoped_collection
      super.includes :participant, :challenge_round
    end

    def find_resource
      scoped_collection.find(params[:id])
    end

    def permitted_params
      params.permit!
    end

    def destroy_resource(object)
      object.update!(deleted: true)
    end
  end

  form do |f|
    f.inputs 'Submission' do
      f.input :challenge,
              as:         :searchable_select,
              collection: Challenge.all.map { |challenge|
                            [challenge.challenge, challenge.id]
                          }
      f.input :challenge_round_id
      f.input :participant_id,
              label:      'Participant',
              as:         :searchable_select,
              collection: Participant.all.order(:name).map { |u| ["#{u.name} - #{u.id}", u.id] }
      f.input :score
      f.input :score_secondary
      f.input :description_markdown
      f.input :grading_status,
              as:         :searchable_select,
              collection: enum_option_pairs(Submission, :grading_status)
      f.input :grading_message
      f.input :post_challenge
      f.input :media_large
      f.input :media_thumbnail
      f.input :media_content_type
      f.input :vote_count
    end
    f.actions
  end

  csv do
    column :id
    column :participant_id
    column(:participant) { |submission| submission.participant&.name.to_s }
    column :score
    column :score_secondary
    column :meta
    column :grading_status_cd
    column :grading_message
    column :post_challenge
    column :media_content_type
    column :created_at
    column :updated_at
  end

  batch_action 'Re-Evaluate Submissions', priority: 1 do |ids|
    ids.each do |sub_id|
      SubmissionGraderJob.perform_later(sub_id)
    end
    redirect_to admin_challenge_submissions_path, alert: 'Submissions are being revaluated'
  end
end
