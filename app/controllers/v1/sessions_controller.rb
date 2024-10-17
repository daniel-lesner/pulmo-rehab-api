# frozen_string_literal: true

module V1
  class SessionsController < ApplicationController
    skip_before_action :authenticate_user, only: [ :create ]
  end
end
