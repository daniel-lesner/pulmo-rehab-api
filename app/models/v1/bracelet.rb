# frozen_string_literal: true

module V1
  class Bracelet < ApplicationRecord
    belongs_to :user

    validates :name, :brand, :token, :token_secret, presence: true
    # validates :token, uniqueness: true
    # validates :brand, inclusion: { in: [ :garmin, :xiaomi, :huawei ] }

    before_save :set_token_and_token_secret, if: -> { brand == "Fitbit" && new_record? }

    def set_token_and_token_secret
      token_data = FitbitService.exchange_auth_code(token)

      if token_data["access_token"]
        self.token = token_data["access_token"]
        self.token_secret = token_data["refresh_token"]
      end
    end
  end
end
