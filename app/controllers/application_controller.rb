# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include JSONAPI::ActsAsResourceController
  include Pundit::Authorization

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :null_session

  before_action :authenticate_user

  rescue_from Pundit::NotAuthorizedError, with: :forbidden_error
  rescue_from ActiveRecord::RecordNotFound, with: :not_found_error

  def context
    { current_user: current_user }
  end

  def show
    record = get_model_from_request.find(request.params[:id])
    authorize(record)
    super
  end

  def create
    authorize(get_model_from_request)
    super
  end

  def destroy
    record = get_model_from_request.find(request.params[:id])
    authorize(record)
    super
  end

  private

    def authenticate_user
      token = request.headers["Authorization"]&.split(" ")&.last

      user = V1::User.find_by(password_token: token) || V1::Doctor.find_by(password_token: token)

      if user
        @current_user = user
      else
        not_authorized_error
      end
    end

    def current_user
      @current_user
    end

    def get_model_from_request
      request.params[:controller].split("/").map(&:capitalize).map(&:singularize).join("::").constantize
    end

    def not_authorized_error
      body = {
          errors: [
            {
              status: "401",
              code: "401",
              title: "Unauthorized",
              detail: "You need to be authenticated to perform this operation"
            }
          ]
        }

      render(json: body, status: :unauthorized)
    end

    def forbidden_error
      body = {
        errors: [
          {
            status: "403",
            code: "403",
            title: "Forbidden",
            detail: "You don't have appropriate permissions to perform this operation"
          }
        ]
      }

      render(json: body, status: :forbidden)
    end

    def not_found_error
      id = request.parameters[:id]

      body = {
        errors: [
          {
            status: "404",
            code: "404",
            title: "Record not found",
            details: "The record identified by #{id} could not be found."
          }
        ]
      }

      render(json: body, status: :not_found)
    end
end
