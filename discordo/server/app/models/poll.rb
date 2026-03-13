class Poll < ApplicationRecord
  belongs_to :message
  has_many :votes, class_name: 'PollVote', dependent: :destroy
  
  serialize :options, Array
  
  def results
    votes.group(:option_index).count
  end
  
  def voted?(user_id)
    votes.exists?(user_id: user_id)
  end
end
