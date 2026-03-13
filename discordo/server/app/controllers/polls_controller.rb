class PollsController < ApplicationController
  
  # POST /polls
  def create
    message = Message.find(params[:poll][:message_id])
    poll = message.create_poll(poll_params)
    
    if poll.save
      render json: poll, status: :created
    else
      render json: { errors: poll.errors.full_messages }, status: :unprocessable_entity
    end
  end
  
  private
  
  def poll_params
    params.require(:poll).permit(:question, options: [])
  end
end
