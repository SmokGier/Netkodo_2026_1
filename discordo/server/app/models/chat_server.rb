class ChatServer < ApplicationRecord
  belongs_to :owner, class_name: 'User', optional: true
  
  validates :name, presence: true, uniqueness: true, length: { minimum: 2, maximum: 30 }
  
  def private?
    password_digest.present?
  end
  
  def correct_password?(password)
    if password_digest.blank?
      true
    elsif password.blank?
      false
    else
      BCrypt::Password.new(password_digest) == password rescue false
    end
  end
end
