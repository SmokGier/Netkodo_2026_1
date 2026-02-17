class TasksController < ApplicationController
  skip_before_action :verify_authenticity_token
  def index; render json: Task.all; end
  def create
    task = Task.create!(task_params)
    ActionCable.server.broadcast("tasks_channel", { action: "created", task: task })
    render json: task, status: :created
  end
  def update
    task = Task.find(params[:id]); task.update!(task_params)
    ActionCable.server.broadcast("tasks_channel", { action: "updated", task: task })
    render json: task
  end
  def destroy
    task = Task.find(params[:id]); task.destroy
    ActionCable.server.broadcast("tasks_channel", { action: "deleted", id: params[:id] })
    head :no_content
  end
  private
  def task_params = params.require(:task).permit(:title, :description, :completed)
end
