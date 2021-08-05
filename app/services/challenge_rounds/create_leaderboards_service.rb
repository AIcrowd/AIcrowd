module ChallengeRounds
  class CreateLeaderboardsService < ::BaseService
    def initialize(challenge_round:, meta_challenge_id: nil, ml_challenge_id: nil, challenge_leaderboard_extra: nil, is_freeze: nil)
      @challenge_round       = challenge_round
      @challenge             = @challenge_round.challenge
      @submissions           = @challenge_round.submissions.reorder(created_at: :desc)
      @meta_challenge_id     = meta_challenge_id
      @ml_challenge_id       = ml_challenge_id
      @challenge_leaderboard_extra = challenge_leaderboard_extra
      if challenge_leaderboard_extra.nil?
        @challenge_leaderboard_extra = @challenge_round.default_leaderboard
      end

      @is_freeze             = is_freeze
      @is_borda_ranking      = false

      if @meta_challenge_id.blank? && @ml_challenge_id.blank?
        @team_participants_ids = @challenge.team_participants.pluck(:participant_id)
        @team_challenge_id     = @challenge.id
      elsif @ml_challenge_id.present?
        @team_participants_ids = Challenge.find(@ml_challenge_id).team_participants.pluck(:participant_id)
        @team_challenge_id     = @ml_challenge_id
      else
        @team_participants_ids = Challenge.find(@meta_challenge_id).team_participants.pluck(:participant_id)
        @team_challenge_id     = @meta_challenge_id
      end
    end

    def call
      ActiveRecord::Base.transaction do
        truncate_scores

        delete_entries = BaseLeaderboard.where(challenge_round: challenge_round)
        delete_entries = dynamic_filters(delete_entries, deletion=true)
        delete_entries.delete_all

        populate_borda_field_if_required

        leaderboards          = build_base_leaderboards('leaderboard', [false], freeze_time)
        previous_leaderboards = build_base_leaderboards('leaderboard', [false], window_border_dttm([false]))

        create_leaderboards(leaderboards, previous_leaderboards)
        if leaderboards.present? && leaderboards.first.ml_challenge_id.present?
          award_point_for_legendary_submission(leaderboards.first(3))
          award_point_for_rank_change(leaderboards)
        end

        ongoing_leaderboards          = build_base_leaderboards('ongoing', [true, false], Time.current)
        previous_ongoing_leaderboards = build_base_leaderboards('ongoing', [true, false], window_border_dttm([true, false]))

        create_leaderboards(ongoing_leaderboards, previous_ongoing_leaderboards)
      end
      success
    end

    private

    attr_reader :challenge_round, :challenge, :submissions, :window_border, :meta_challenge_id, :ml_challenge_id, :team_participants_ids, :team_challenge_id

    def populate_borda_field_if_required
      # Magically populate borda ranks when enabled
      first_submission = @submissions.first
      if !first_submission.nil? && !first_submission['meta'].nil? && !first_submission['meta']['private_borda_ranking_enabled'].nil?
        @is_borda_ranking = true
        ChallengeRounds::PopulateBordaFieldsService.new(challenge_round_id: @challenge_round.id).call
      end
    end

    def truncate_scores
      submissions
        .update_all([
          'score_display = ROUND(score::numeric, ?), score_secondary_display = ROUND(score_secondary::numeric, ?)',
          @challenge_leaderboard_extra.score_precision,
          @challenge_leaderboard_extra.score_secondary_precision
        ])
    end

    def build_base_leaderboards(leaderboard_type, post_challenge, cuttoff_dttm)
      users_leaderboards = []

      teams_submissions(post_challenge, cuttoff_dttm).each do |team_id, submissions|
        first_graded_submission = submissions.find { |submission| submission.grading_status_cd == 'graded' }
        next if first_graded_submission.blank?

        users_leaderboards << build_leaderboard(first_graded_submission, submissions.size, 'Team', team_id, leaderboard_type)
      end


      participants_submissions(post_challenge, cuttoff_dttm).each do |participant_id, submissions|
        first_graded_submission = submissions.find { |submission| submission.grading_status_cd == 'graded' }
        next if first_graded_submission.blank?

        users_leaderboards << build_leaderboard(first_graded_submission, submissions.size, 'Participant', participant_id, leaderboard_type)
      end

      migration_submmissions(post_challenge, cuttoff_dttm).each do |submission|
        users_leaderboards << build_leaderboard(submission, 1, nil, nil, leaderboard_type)
      end

      baseline_leaderboards = baseline_submissions(post_challenge, cuttoff_dttm).map do |submission|
        build_leaderboard(submission, 0, 'Participant', submission.participant_id, leaderboard_type)
      end

      assign_row_num(users_leaderboards)

      all_leaderboards    = baseline_leaderboards + users_leaderboards
      sorted_leaderboards = sort_leaderboards(all_leaderboards)

      sorted_leaderboards.each.with_index(1) do |leaderboard, index|
        leaderboard.seq = index
        leaderboard
      end

      sorted_leaderboards
    end

    def create_leaderboards(leaderboards, previous_leaderboards)
      leaderboards.each do |leaderboard|
        previous_leaderboard = previous_leaderboards.find do |previous_leaderboard|
          previous_leaderboard.submitter_id == leaderboard.submitter_id &&
          previous_leaderboard.submitter_type == leaderboard.submitter_type
        end

        next if previous_leaderboard.blank?

        leaderboard.previous_row_num = previous_leaderboard.row_num
      end

      BaseLeaderboard.import!(leaderboards)
    end

    def dynamic_filters(entries, deletion=false)
      if @meta_challenge_id.present?
        entries = entries.where(meta_challenge_id: @meta_challenge_id)
      end

      if @challenge_leaderboard_extra.present? && !deletion
        entries = entries.where(@challenge_leaderboard_extra.filter)
      end

      if deletion
        if @challenge_leaderboard_extra.present?
          if @challenge_leaderboard_extra.default
            entries = entries.where(challenge_leaderboard_extra_id: [nil, @challenge_leaderboard_extra.id])
          else
            entries = entries.where(challenge_leaderboard_extra_id: @challenge_leaderboard_extra.id)
          end
        else
          entries = entries.where(challenge_leaderboard_extra_id: nil)
        end
      end

      return entries
    end

    def teams_submissions(post_challenge, cuttoff_dttm)
      entries = submissions.joins(participant: :teams)
                  .where(teams: { challenge_id: team_challenge_id })
                  .where(challenge_round_id: challenge_round.id, post_challenge: post_challenge, baseline: false)
                  .where('submissions.created_at <= ?', cuttoff_dttm)
      entries = dynamic_filters(entries)
      entries = entries.select('teams.id AS team_id, submissions.*')
                  .reorder(submissions_order)
                  .group_by { |submission| submission.team_id }
      return entries
    end

    def participants_submissions(post_challenge, cuttoff_dttm)
      entries = submissions.joins(:participant)
                  .where.not(participant_id: team_participants_ids)
                  .where(challenge_round_id: challenge_round.id, post_challenge: post_challenge, baseline: false)
                  .where('submissions.created_at <= ?', cuttoff_dttm)
      entries = dynamic_filters(entries)
      entries = entries.reorder(submissions_order)
                  .group_by { |submission| submission.participant_id }
      return entries
    end

    def migration_submmissions(post_challenge, cuttoff_dttm)
      entries = submissions.left_joins(:participant)
                  .where(challenge_round_id: challenge_round.id, post_challenge: post_challenge, baseline: false, grading_status_cd: 'graded')
                  .where('submissions.created_at <= ?', cuttoff_dttm)
                  .where('participants.id IS NULL')
      entries = dynamic_filters(entries)
      entries = entries.reorder(submissions_order)
      return entries
    end

    def baseline_submissions(post_challenge, cuttoff_dttm)
      entries = challenge_round.submissions
                  .where(challenge_round_id: challenge_round.id, post_challenge: post_challenge, baseline: true, grading_status_cd: 'graded')
                  .where('submissions.created_at <= ?', cuttoff_dttm)
      entries = dynamic_filters(entries)
      return entries
    end

    def build_leaderboard(submission, submissions_count, submitter_type, submitter_id, leaderboard_type = 'leaderboard')
      score = submission.score
      if @challenge_leaderboard_extra.dynamic_score_field.present?
        score = submission["meta"][@challenge_leaderboard_extra.dynamic_score_field].presence || nil
      end
      score = score.to_f.round(@challenge_leaderboard_extra.score_precision)

      score_secondary = submission.score_secondary
      if @challenge_leaderboard_extra.dynamic_score_secondary_field.present?
        score_secondary = submission["meta"][@challenge_leaderboard_extra.dynamic_score_secondary_field].presence || nil
      end
      score_secondary = score_secondary.to_f.round(@challenge_leaderboard_extra.score_secondary_precision)

      BaseLeaderboard.new(
        meta_challenge_id:    meta_challenge_id,
        ml_challenge_id:      ml_challenge_id,
        challenge_id:         challenge.id,
        challenge_round_id:   challenge_round.id,
        submitter_type:       submitter_type,
        submitter_id:         submitter_id,
        submission_id:        submission.id,
        seq:                  0,
        row_num:              0,
        previous_row_num:     0,
        entries:              submissions_count,
        score:                score,
        score_secondary:      score_secondary,
        meta:                 submission.meta,
        media_large:          submission.media_large,
        media_thumbnail:      submission.media_thumbnail,
        media_content_type:   submission.media_content_type,
        description:          submission.description,
        description_markdown: submission.description_markdown,
        leaderboard_type_cd:  leaderboard_type,
        post_challenge:       submission.post_challenge,
        baseline:             submission.baseline,
        baseline_comment:     submission.baseline_comment,
        submission_link:      submission.submission_link,
        challenge_leaderboard_extra_id: @challenge_leaderboard_extra.id,
        refreshed_at:         Time.current,
        created_at:           submission.created_at,
        updated_at:           submission.updated_at
      )
    end

    def sort_map(sort_field)
      case sort_field
      when 'ascending'
        return 'asc'
      when 'descending'
        return 'desc'
      else
        return nil
      end
    end

    def submissions_order
      return 'updated_at desc' if challenge.latest_submission == true

      return "meta->>'private_borda_ranking_rank_sum' asc" if @is_borda_ranking

      score_field = "score"
      if @challenge_leaderboard_extra.dynamic_score_field.present?
        score_field = "CAST(meta->>'#{@challenge_leaderboard_extra.dynamic_score_field}' as decimal)"
      end

      if @challenge_leaderboard_extra.score_precision.present?
        score_field = "ROUND(CAST(#{score_field} as numeric), #{@challenge_leaderboard_extra.score_precision})"
      end

      score_secondary_field = "score_secondary"
      if @challenge_leaderboard_extra.dynamic_score_secondary_field.present?
        score_secondary_field = "CAST(meta->>'#{@challenge_leaderboard_extra.dynamic_score_secondary_field}' as decimal)"
      end

      if @challenge_leaderboard_extra.score_secondary_precision.present?
        score_secondary_field = "ROUND(CAST(#{score_secondary_field} as numeric), #{@challenge_leaderboard_extra.score_secondary_precision})"
      end

      score_sort_order = sort_map(@challenge_leaderboard_extra.primary_sort_order_cd)
      return "#{score_field} #{score_sort_order} NULLS LAST, created_at asc" if @challenge_leaderboard_extra.secondary_sort_order_cd.blank? || @challenge_leaderboard_extra.secondary_sort_order_cd == 'not_used'

      secondary_sort_order = sort_map(@challenge_leaderboard_extra.secondary_sort_order_cd)
      return "#{score_field} #{score_sort_order} NULLS LAST, #{score_secondary_field} #{secondary_sort_order} NULLS LAST, created_at asc"
    end

    def sort_leaderboards(all_leaderboards)
      return all_leaderboards.sort_by { |leaderboard| leaderboard['meta']['private_borda_ranking_rank_sum'].to_i } if @is_borda_ranking

      score_sort_order = sort_map(@challenge_leaderboard_extra.primary_sort_order_cd)

      if @challenge_leaderboard_extra.secondary_sort_order_cd.blank? || @challenge_leaderboard_extra.secondary_sort_order_cd == 'not_used'
        sorted_leaderboards = all_leaderboards.sort_by do |leaderboard|
          score      = score_sort_order == 'asc' ? leaderboard.score.to_f : leaderboard.score.to_f * -1
          created_at = leaderboard.created_at
          [score, created_at]
        end

        return sorted_leaderboards
      end

      secondary_sort_order = sort_map(@challenge_leaderboard_extra.secondary_sort_order_cd)

      all_leaderboards.sort_by do |leaderboard|
        first_column     = score_sort_order == 'asc' ? leaderboard.score.to_f : leaderboard.score.to_f * -1
        secondary_column = secondary_sort_order == 'asc' ? leaderboard.score_secondary.to_f : leaderboard.score_secondary.to_f * -1
        created_at = leaderboard.created_at

        [first_column, secondary_column, created_at]
      end
    end

    def assign_row_num(leaderboards)
      sorted_leaderboards = sort_leaderboards(leaderboards)

      current_row_num  = 1
      same_score_count = 0

      sorted_leaderboards.each.with_index do |leaderboard, index|
        leaderboard.row_num = current_row_num
        next_leaderboard    = sorted_leaderboards[index + 1]

        next if next_leaderboard.blank?

        if !@challenge_leaderboard_extra.is_tie_possible
            current_row_num += 1
            next
        end

        if @is_borda_ranking
          if next_leaderboard['meta']['private_borda_ranking_rank_sum'] == leaderboard['meta']['private_borda_ranking_rank_sum']
            same_score_count += 1
          else
            current_row_num  += 1 + same_score_count
            same_score_count = 0
          end
          next
        end

        if @challenge_leaderboard_extra.secondary_sort_order_cd.blank? || @challenge_leaderboard_extra.secondary_sort_order_cd == 'not_used'
          if next_leaderboard.score == leaderboard.score
            same_score_count += 1
          else
            current_row_num  += 1 + same_score_count
            same_score_count = 0
          end
        else
          if next_leaderboard.score == leaderboard.score && next_leaderboard.score_secondary == leaderboard.score_secondary
            same_score_count += 1
          else
            current_row_num  += 1 + same_score_count
            same_score_count = 0
          end
        end
      end
    end

    def window_border_dttm(post_challenge)
      get_submissions = if @ml_challenge_id.present?
                          submissions.find_by(post_challenge: post_challenge, ml_challenge_id: ml_challenge_id)
                        else
                          submissions.find_by(post_challenge: post_challenge, meta_challenge_id: meta_challenge_id)
                        end
      (get_submissions&.created_at || Time.current) - @challenge_leaderboard_extra.ranking_window.hours
    end

    def freeze_time
      @is_freeze
    end

    def freeze_dttm
      return Time.current if @challenge_round.end_dttm.nil?

      @challenge_round.end_dttm - @challenge_leaderboard_extra.freeze_duration.hours
    end

    def award_point_for_legendary_submission(top_3_leaderboards)
      top_3_leaderboards.each do |leaderboard|
        MlChallenge::AwardPointJob.perform_now(leaderboard, 'legendary_submission')
      end
    end

    def award_point_for_rank_change(leaderboards)
      leaderboards.find do |leaderboard|
        next if leaderboard.previous_row_num.zero?

        MlChallenge::AwardPointJob.perform_now(leaderboard, 'leaderboard_rank_change') if leaderboard.previous_row_num < leaderboard.row_num
      end
    end
  end
end
