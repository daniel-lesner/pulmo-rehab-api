# frozen_string_literal: true

module V1
  class SessionResource < PoroResource
    model_name "V1::Session"

    attributes :email, :password, :password_token

    def fetchable_fields
      super - [ :password ]
    end

    def save
      password_token = V1::User.find_by(email: @model.email, password: @model.password)&.password_token
      @model.password_token = password_token
      context[:created_model] = @model
    end

    class << self
    end
  end
end
