class User < ApplicationRecord
  has_secure_password
  
  validates :username, presence: true, uniqueness: true, length: { minimum: 2, maximum: 20 }
  validates :password, length: { minimum: 6 }, if: -> { new_record? || !password.nil? }
  
  before_create :generate_api_token, :generate_keys
  
  private
  
  def generate_api_token
    loop do
      self.api_token = SecureRandom.hex(32)
      break unless User.exists?(api_token: self.api_token)
    end
  end
  
  def generate_keys
    self.public_key = SecureRandom.hex(32)
  end
end
