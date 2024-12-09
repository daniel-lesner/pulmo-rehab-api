# frozen_string_literal: true

module V1
  class UserResource < ApplicationResource
    model_name "V1::User"

    attributes :name, :email, :password, :password_token, :password_token_expires_at

    has_many :bracelets

    def fetchable_fields
      super - [ :password ]
    end
  end
end
