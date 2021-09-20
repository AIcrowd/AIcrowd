Challenge.create!([
  {id: 100,
    answer_file_s3_key: nil,
    api_required: false,
    challenge: "Spotify Sequential Skip Prediction Challenge",
    challenge_client_name: "spotify-sequential-skip-prediction-challenge",
    clef_task_id: nil,
    clef_challenge: false,
    dataset_description_markdown: "this is the dataset license",
    description_markdown: File.read('description.md'),
    dynamic_content_flag: false,
    dynamic_content: nil,
    dynamic_content_tab: nil,
    evaluation_markdown: File.read('evaluation.md'),
    featured_sequence: 10,
    remote_image_file_url: "https://dnczkxd1gcfu5.cloudfront.net/images/challenges/image_file/50/spotify.png",
    # image_file: "https://dnczkxd1gcfu5.cloudfront.net/images/challenges/image_file/50/spotify.png",
    license_markdown: "this is the license",
    grader_identifier: "crowdAI_GRADER_POOL",
    grader_logs: true,
    grading_history: true,
    media_on_leaderboard: false,
    online_grading: true,
    online_submissions: true,
    page_views: 30800,
    participant_count: 6300,
    perpetual_challenge: false,
    post_challenge_submissions: false,
    prize_cash: "$1 Million USD",
    prize_academic: "8",
    prize_misc: "Some other things",
    prizes_markdown: File.read('prizes.md'),
    private_challenge: false,
    require_registration: false,
    resources_markdown: File.read('resources.md'),
    rules_markdown: File.read('rules.md'),
    slug: "train-schedule-optimisation-challenge",
    show_leaderboard: true,
    status_cd: "running",
    submissions_count: 4100,
    submission_license: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aenean vel malesuada leo, in efficitur erat. Nam id purus nulla. Cras ac libero eget diam luctus ultrices. Orci varius natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Mauris tempor aliquet malesuada. Interdum et malesuada fames ac ante ipsum primis in faucibus. Phasellus at quam ac enim elementum placerat luctus euismod dui. Suspendisse ligula lacus, luctus vel placerat vitae, varius ac sem. Quisque venenatis lectus eu nulla commodo molestie. Vestibulum consectetur elit dictum risus consequat, at laoreet risus euismod.",
    submissions_page: true,
    tagline: "Predict if users will skip or listen to the music they're streamed",
    toc_acceptance_instructions_markdown: "This is the challenge terms",
    require_toc_acceptance: true,
    vote_count: 55,
    winner_description_markdown: "winner description markdown",
    winners_tab_active: false,
}])

ChallengeRound.create!([
  {id: 101,
    challenge_id: 100,
    challenge_round: "Public Evaluation",
    active: true,
    submission_limit: 2,
    submission_limit_period_cd: "day",
    start_dttm: 10.days.ago,
    end_dttm: Time.now + 10.days,
    minimum_score: nil,
    minimum_score_secondary: nil,
    ranking_highlight: 3,
  },
  {id: 102,
    challenge_id: 100,
    challenge_round: "Round 1",
    active: true,
    submission_limit: 5,
    submission_limit_period_cd: "day",
    start_dttm: "2018-08-08 12:00:00",
    end_dttm: "2018-11-09 12:00:00",
    minimum_score: nil,
    minimum_score_secondary: nil,
    ranking_highlight: 3,
  },
  {id: 103,
    challenge_id: 100,
    challenge_round: "Final Evaluation",
    active: false,
    submission_limit: 5,
    submission_limit_period_cd: "day",
    start_dttm: "2018-08-11 12:00:00",
    end_dttm: "2018-12-31 12:00:00",
    minimum_score: nil,
    minimum_score_secondary: nil,
    ranking_highlight: 3,
  }
])

ChallengePartner.create!([
  {
    challenge_id: 100,
    remote_image_file_url: "https://dnczkxd1gcfu5.cloudfront.net/images/challenge_partners/image_file/54/SDSC_logo.png",
    partner_url: "https://datascience.ch/"
  },
  {
    challenge_id: 100,
    remote_image_file_url: "https://dnczkxd1gcfu5.cloudfront.net/images/challenge_partners/image_file/55/spotify.png",
    partner_url: "https://www.spotify.com/"
  }

])

Submission.create!([

    {id: 135111, challenge_id: 100, participant_id: 1020, score: 80000.2, created_at: "2018-08-15 15:05:56", updated_at: "2018-08-15 15:06:01", score_secondary: 2.0, grading_status_cd: "graded", description_markdown: "", post_challenge: false, challenge_round_id: 102, score_display: 80000.2, score_secondary_display: 0.0, baseline: false, baseline_comment: nil},
    {id: 135109, challenge_id: 100, participant_id: 1020, score: nil, created_at: "2018-08-15 14:40:42", updated_at: "2018-08-15 14:40:46", score_secondary: nil, grading_status_cd: "failed", description_markdown: "", post_challenge: false, challenge_round_id: 102, score_display: nil, score_secondary_display: nil, baseline: false, baseline_comment: nil},
    {id: 121926, challenge_id: 100, participant_id: 7420, score: 13.70000005, created_at: "2018-08-10 15:48:32", updated_at: "2018-08-10 15:50:48", score_secondary: 4.0, grading_status_cd: "graded", description_markdown: "Second submission with slight variation", post_challenge: false, challenge_round_id: 102, score_display: 1003.7, score_secondary_display: 3.0, baseline: false, baseline_comment: nil},
    {id: 129139, challenge_id: 100, participant_id: 7420, score: 103.0, created_at: "2018-08-10 18:35:06", updated_at: "2018-08-10 18:36:55", score_secondary: 6.0, grading_status_cd: "graded", description_markdown: "Scoring test", post_challenge: false, challenge_round_id: 102, score_display: 101003.0, score_secondary_display: 5.0, baseline: false, baseline_comment: nil},
    {id: 121949, challenge_id: 100, participant_id: 7420, score: 363.5999981, created_at: "2018-08-10 20:30:48", updated_at: "2018-08-10 20:32:35", score_secondary: 3.0, grading_status_cd: "graded", description_markdown: "", post_challenge: false, challenge_round_id: 102, score_display: 363.6, score_secondary_display: 6.0, baseline: false, baseline_comment: nil},
    {id: 129818, challenge_id: 100, participant_id: 1235, score: 30581.9166792, created_at: "2018-08-11 08:07:46", updated_at: "2018-08-11 08:08:40", score_secondary: 1.0, grading_status_cd: "graded", description_markdown: "", post_challenge: false, challenge_round_id: 102, score_display: 30581.917, score_secondary_display: 3.0, baseline: false, baseline_comment: nil},
    {id: 121990, challenge_id: 100, participant_id: 7420, score: nil, created_at: "2018-08-11 08:38:59", updated_at: "2018-08-11 08:39:04", score_secondary: nil, grading_status_cd: "failed", description_markdown: "", post_challenge: false, challenge_round_id: 102, score_display: nil, score_secondary_display: nil, baseline: false, baseline_comment: nil},
    {id: 129914, challenge_id: 100, participant_id: 1235, score: 30581.9166792, created_at: "2018-08-11 09:27:50", updated_at: "2018-08-11 09:28:50", score_secondary: 0.0, grading_status_cd: "graded", description_markdown: "", post_challenge: false, challenge_round_id: 102, score_display: 30581.917, score_secondary_display: 2.0, baseline: false, baseline_comment: nil},
    {id: 131615, challenge_id: 100, participant_id: 1020, score: 60001.6000001, created_at: "2018-08-16 16:01:34", updated_at: "2018-08-16 16:01:53", score_secondary: 0.0, grading_status_cd: "graded", description_markdown: "", post_challenge: false, challenge_round_id: 102, score_display: 60001.6, score_secondary_display: 0.0, baseline: false, baseline_comment: nil},
    {id: 129125, challenge_id: 100, participant_id: 7420, score: 344.5, created_at: "2018-08-10 15:34:15", updated_at: "2018-08-10 15:36:03", score_secondary: 0.0, grading_status_cd: "graded", description_markdown: "Trivial not completely working solution to test submission process", post_challenge: false, challenge_round_id: 102, score_display: 344.5, score_secondary_display: 0.0, baseline: false, baseline_comment: nil},
    {id: 121991, challenge_id: 100, participant_id: 3272, score: 765.872345, created_at: "2018-08-12 08:48:59", updated_at: "2018-08-12 08:49:04", score_secondary: 0.0, grading_status_cd: "graded", description_markdown: "", post_challenge: false, challenge_round_id: 102, score_display: 765.872345, score_secondary_display: nil, baseline: false, baseline_comment: nil},
    {id: 129195, challenge_id: 100, participant_id: 3272, score: 777.9166792, created_at: "2018-08-13 09:27:50", updated_at: "2018-08-13 09:28:50", score_secondary: 0.0, grading_status_cd: "graded", description_markdown: "", post_challenge: false, challenge_round_id: 102, score_display: 777.9166792, score_secondary_display: 0.0, baseline: false, baseline_comment: nil},
    {id: 136116, challenge_id: 100, participant_id: 3272, score: nil, created_at: "2018-08-16 16:02:34", updated_at: "2018-08-16 16:03:53", score_secondary: nil, grading_status_cd: "failed", description_markdown: "", post_challenge: false, challenge_round_id: 102, score_display: nil, score_secondary_display: nil, baseline: false, baseline_comment: nil, meta: {"key1" => "value1", "key2" => "value2", "private-key1" => "value3"}},
])


ChallengeRules.create!([

    {
     id: 21321,
     challenge_id: 100,
     terms: "These are some test rules",
     instructions: "Test instructions",
     version: 1,
    }


])
