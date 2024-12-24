# frozen_string_literal: true

module V1
  class Session < VirtualRecord
    attr_accessor :id, :user_id, :email, :password, :password_token, :is_doctor
  end
end
