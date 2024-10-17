# frozen_string_literal: true

module V1
  class Session < VirtualRecord
    attr_accessor :id, :email, :password, :password_token
  end
end
