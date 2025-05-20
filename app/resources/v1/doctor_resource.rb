# frozen_string_literal: true

module V1
  class DoctorResource < ApplicationResource
    model_name "V1::Doctor"

    attributes :name, :email, :password, :password_token, :password_token_expires_at, :registration_key

    has_many :users

    def fetchable_fields
      super - [ :password, :password_token, :password_token_expires_at ]
    end
  end
end
