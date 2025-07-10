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
  rescue_from ActiveRecord::RecordInvalid, with: :invalid_record_error

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
      user ? @current_user = user : not_authorized_error
    end

    def current_user
      @current_user
    end

    def get_model_from_request
      request.params[:controller].split("/").map { |p| p.camelize.singularize }.join("::").constantize
    end

    def not_found_error
      render json: {
        errors: [ {
          status: "404",
          title: "Record not found",
          detail: "No record found for ID #{params[:id]}"
        } ]
      }, status: :not_found
    end

    def forbidden_error
      render json: {
        errors: [ {
          status: "403",
          title: "Forbidden",
          detail: "You are not authorized to perform this action."
        } ]
      }, status: :forbidden
    end

    def not_authorized_error
      render json: {
        errors: [ {
          status: "401",
          title: "Unauthorized",
          detail: "You must be logged in."
        } ]
      }, status: :unauthorized
    end

    def invalid_record_error(exception)
      record = exception.record

      errors = record.errors.map do |error|
        {
          status: "422",
          code: "validation_error",
          title: "Invalid Attribute",
          detail: error.full_message,
          source: { pointer: "/data/attributes/#{error.attribute}" }
        }
      end

      render json: { errors: errors }, status: :unprocessable_entity
    end
end
