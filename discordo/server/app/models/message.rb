class Message < ApplicationRecord
  belongs_to :user, optional: true
  has_many :reactions, dependent: :destroy
end
