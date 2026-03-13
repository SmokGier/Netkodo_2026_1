class PollVotesController < ApplicationController
  
  # POST /poll_votes
  def create
    poll = Poll.find(params[:poll_vote][:poll_id])
    user_id = session[:user_id]
    
    if user_id && !poll.voted?(user_id)
      vote = poll.votes.new(
        user_id: user_id,
        option_index: params[:poll_vote][:option_index]
      )
      
      if vote.save
        # Broadcast vote update
        ActionCable.server.broadcast(
          "poll_channel_#{poll.id}",
          {
            action: "new_vote",
            poll_id: poll.id,
            results: poll.results
          }
        )
        render json: { success: true, results: poll.results }
      else
        render json: { errors: vote.errors.full_messages }, status: :unprocessable_entity
      end
    else
      render json: { error: 'Already voted or unauthorized' }, status: :unprocessable_entity
    end
  end
end
