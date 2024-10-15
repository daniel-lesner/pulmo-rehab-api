# frozen_string_literal: true

module V1
  class UsersController < ApplicationController
    skip_before_action :authenticate_user, only: [ :create ]
  end
end
