class Invite < ApplicationRecord
  belongs_to :chat_server
  belongs_to :creator, class_name: 'User', optional: true
  
  before_create :generate_code
  
  validates :chat_server_id, presence: true
  validates :code, uniqueness: true
  
  def generate_code
    self.code = SecureRandom.hex(8) if code.blank?
  end
  
  def expired?
    expires_at && expires_at < Time.current
  end
  
  def used!
    decrement!(:uses_left) if uses_left
  end
  
  def valid?
    !expired? && (uses_left.nil? || uses_left > 0)
  end
end
