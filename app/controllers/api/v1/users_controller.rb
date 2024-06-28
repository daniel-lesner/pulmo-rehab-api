class Api::V1::UsersController < ApplicationController

    def create
      user = User.new(user_params)

      if user.save
        render json: {
          data: {
            type: "users",
            id: user.id.to_s,
            attributes: {
              email: user.email,
              authentication_token: user.authentication_token,
              created_at: user.created_at,
              updated_at: user.updated_at
            }
          }
        }, status: :created
      else
        render json: {
          errors: user.errors.full_messages.map do |message|
            { detail: message }
          end
        }, status: :unprocessable_entity
      end
    end
  
    private
  
    def user_params
      params.require(:data).require(:attributes).permit(:email, :password, :password_confirmation)
    end
  end