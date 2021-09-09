# Be sure to restart your server when you modify this file.
#
# Points are a simple integer value which are given to "meritable" resources
# according to rules in +app/models/merit/point_rules.rb+. They are given on
# actions-triggered, either to the action user or to the method (or array of
# methods) defined in the +:to+ option.
#
# 'score' method may accept a block which evaluates to boolean
# (recieves the object as parameter)

module Merit
  class PointRules
    include Merit::PointRulesMethods

    def initialize
      # score 10, :on => 'users#create' do |user|
      #   user.bio.present?
      # end
      #
      # score 15, :on => 'reviews#create', :to => [:reviewer, :reviewed]
      #
      # score 20, :on => [
      #   'comments#create',
      #   'photos#create'
      # ]
      #
      # score -10, :on => 'comments#destroy'


      score 1, :on => 'votes#create', category: 'liked-5-challenge-badge'

      score -1, :on => 'votes#destroy', category: 'destroyed-challenge-like'

      # Followed n number of challenges

      score 1, :on => 'follows#create', category: 'followed-5-challenge'

      score 1, :on => 'follows#destroy', category: 'destroy-challenge-follow'

      # Participated in n number of challenges

      score 1, :on => ['challenge_participants#create', 'challenge_participants#update'], category: 'participated-in-5-challenge'

      # Badges for number of submissions

      score 1, :on => 'submissions#create', category: 'submitted-40-submissions'

      # Badges for number of successful submissions

      score 1, :on => 'submissions#create', category: 'submitted-successful-submissions' do |submission|
        submission.grading_status_cd == 'graded'
      end


      # Badges for winning a challenge
      # Liked n number of practice problems

      score 1, :on => 'votes#create', category: 'liked-10-practice-problems' do |vote|
        vote.votable_type == "Challenge" && vote.votable.practice_flag == true
      end

      # Shared n number of practice problems
      # Followed n number of practice problems

      score 1, :on => 'follows#create', category: 'followed-10-practice-problems' do |follow|
        follow.followable_type == "Challenge" && follow.followable.practice_flag == true
      end

      # Participate in n number of practice problems

      score 1, :on => ['challenge_participants#create', 'challenge_participants#update'], category: 'participated-in-10-practice-problems' do |challenge_participant|
        challenge_participant.challenge.practice_flag == true
      end

      # N number of successful submissions in practice problems

      score 1, :on => 'submissions#create', category: 'submitted-20-successful-practice-problems' do |submission|
        submission.grading_status_cd = 'graded' && submission.challenge.practice_flag == true
      end

      # Badges for consecutive days submissions

      score 1, :on => 'submissions#create', category: 'submitted-40-submissions' do |submission|
        submission.participant.submissions.count == 40
      end

      score 1, :on => 'submissions#create', category: 'submitted-80-submissions' do |submission|
        submission.participant.submissions.count == 80
      end

      score 1, :on => 'submissions#create', category: 'submitted-120-submissions' do |submission|
        submission.participant.submissions.count == 120
      end

      # Badges for rank improvement
      # Badges for score improvement
      # Actively participated in one challenge, made 2 submissions and liked 2 challenges.
      # Badges for inviting users


      # Notebook Related Badges

      # Create Notebook Badges

      score 1, :on => 'posts#create', category: 'created-notebook'

      score -1, :on => 'posts#destroy', category: 'created-notebook'


      # Notebook shared n times

      # Participant liked notebooks n number of times

      score 1, :on => 'votes#create', category: 'liked-10-notebooks' do |vote|
        vote.votable_type == "Post"
      end

      score -1, :on => 'votes#destroy', category: 'liked-10-notebooks' do |vote|
        vote.votable_type == "Post"
      end



      # Participant Notebooks were liked n number of times

      score 1, :on => 'votes#create', category: 'notebook-liked-5',  to: :participant do |vote|
        vote.votable.is_a?(Post)
      end

      score 1, :on => 'votes#destroy', category: 'notebook-liked-20',  to: :participant do |vote|
        vote.votable.is_a?(Post)
      end

      # Participant commented on a notebook n number of times
      # Participant notebooks received n number of comments
      # Subscribed n times
      # N subscribers
      # Download notebooks
      # Created one notebook, like 3 notebooks, shared 2 notebooks
      # Created n number of blitz notebooks


      # Created first notebook

      # Shared first notebook
      # Notebook was shared first time

      # Liked 1 notebook

      # Notebook got first like


      # Commented on 1 notebook
      # Notebook got 1 comment
      # You subscribed to your 1st notebook
      # Your notebook got 1st subscriber
      # You downloaded your 1st notebook
      # Your notebook got its 1st download
      # Listing all the first time badges
    end
  end
end