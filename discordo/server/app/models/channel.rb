class Channel < ApplicationRecord
  belongs_to :chat_server
  has_many :messages, dependent: :destroy
  
  validates :name, presence: true
  validates :chat_server_id, presence: true
  
  scope :ordered, -> { order(position: :asc) }
  scope :in_category, ->(category) { where(category: category) }
end
