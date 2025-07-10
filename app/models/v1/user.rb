# frozen_string_literal: true

module V1
  class User < ApplicationRecord
    has_many :bracelets, dependent: :destroy
    has_one :doctor

    validates :name, presence: true
    validates :email, presence: true, uniqueness: true
    validates :password, presence: true, length: { minimum: 8 }, if: :password_required?
    validate :password_complexity, if: :password_required?

    before_create :set_password_token

    private

      def set_password_token
        self.password_token = generate_password_token
        self.password_token_expires_at = 3.months.from_now
      end

      def generate_password_token
        SecureRandom.hex(16)
      end

      def password_complexity
        return if password.blank?

        unless password =~ /(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[\W_])/
          errors.add :password, "must include at least one lowercase letter, one uppercase letter, one digit, and one special character"
        end
      end

      def password_required?
        new_record? || (password.present? && password_changed?)
      end
  end
end
