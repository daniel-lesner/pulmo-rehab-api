# frozen_string_literal: true

module V1
  class SessionResource < PoroResource
    model_name "V1::Session"

    attributes :user_id, :email, :password, :password_token

    def fetchable_fields
      super - [ :password ]
    end

    def save
      user = V1::User.find_by(email: @model.email, password: @model.password)

      @model.user_id = user&.id
      @model.password_token = user&.password_token

      context[:created_model] = @model
    end
  end
end
