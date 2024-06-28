module Api
    module V1
      class SessionsController < ApplicationController
        # protect_from_forgery with: :null_session
  
        def create
          user = User.find_for_database_authentication(email: session_params[:email])
          if user&.valid_password?(session_params[:password])
            render json: {
              data: {
                id: user.id,
                type: 'sessions',
                attributes: {
                  email: user.email,
                  authentication_token: user.authentication_token
                }
              }
            }, status: :created
          else
            render json: {
              errors: [
                {
                  status: '401',
                  title: 'Unauthorized',
                  detail: 'Invalid email or password'
                }
              ]
            }, status: :unauthorized
          end
        end
  
        private
  
        def session_params
          params.require(:data).require(:attributes).permit(:email, :password)
        end
      end
    end
  end