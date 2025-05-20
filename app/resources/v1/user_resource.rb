# frozen_string_literal: true

module V1
  class UserResource < ApplicationResource
    model_name "V1::User"

    attributes :name, :email, :password, :password_token, :password_token_expires_at, :doctor_id

    has_many :bracelets

    relationship :doctor, to: :one, class_name: "Doctor"

    filter :doctor_id, apply: ->(records, value, _options) {
      if value.include?("null")
        records.where(doctor_id: nil)
      else
        records.where(doctor_id: value)
      end
    }

    def fetchable_fields
      super - [ :password, :password_token, :password_token_expires_at ]
    end
  end
end
