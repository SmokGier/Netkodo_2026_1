class Mention < ApplicationRecord
  belongs_to :message
  belongs_to :mentioned_user, class_name: 'User'
  belongs_to :user, class_name: 'User' # kto wspomniał
  
  after_create :send_notification
  
  private
  
  def send_notification
    # Powiadomienie desktop będzie implementowane w JS
    # Tutaj możemy zapisać w bazie
  end
end
