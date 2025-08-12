# frozen_string_literal: true

module V1
  class AiMessagesController < ApplicationController
    skip_before_action :authenticate_user, only: [ :create ]
  end
end
