# frozen_string_literal: true

module V1
  class SessionsController < ApplicationController
    skip_before_action :authenticate_user, only: [ :create ]

    def create
      email = params["data"]["attributes"]["email"]
      password = params["data"]["attributes"]["password"]

      if V1::User.find_by("email": email, password: password).nil?
        return render json: {
          errors: [
              {
                  "title": "Invalid details",
                  "detail": "password does not match email",
                  "code": "422",
                  "status": "422"
              }
          ]
        }, status: 422
      end

      super
    end
  end
end
