# frozen_string_literal: true

module V1
  class SessionPolicy < ApplicationPolicy
    def create?
      true
    end
  end
end
