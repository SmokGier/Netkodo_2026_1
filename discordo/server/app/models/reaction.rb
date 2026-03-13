class Reaction < ApplicationRecord
  belongs_to :message
  belongs_to :user, optional: true
  
  validates :emoji, presence: true
  validates :message_id, presence: true
end
