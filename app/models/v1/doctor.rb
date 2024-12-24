# frozen_string_literal: true

module V1
  class Doctor < ApplicationRecord
    attr_accessor :registration_key

    has_many :users, dependent: :destroy

    validates :name, presence: true
    validates :email, presence: true, uniqueness: true
    validates :password, presence: true
    validates :registration_key, presence: true
    validate :registration_key_validity

    before_create :set_password_token

    private
      def registration_key_validity
      end

      def set_password_token
        self.password_token = generate_password_token
        self.password_token_expires_at = 3.months.from_now
      end

      def generate_password_token
        SecureRandom.hex(16)
      end
  end
end
