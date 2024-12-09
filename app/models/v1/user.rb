# frozen_string_literal: true

module V1
  class User < ApplicationRecord
    has_many :bracelets, dependent: :destroy

    validates :name, presence: true
    validates :email, presence: true, uniqueness: true
    validates :password, presence: true

    before_create :set_password_token

    private

      def set_password_token
        self.password_token = generate_password_token
        self.password_token_expires_at = 3.months.from_now
      end

      def generate_password_token
        SecureRandom.hex(16)
      end
  end
end
