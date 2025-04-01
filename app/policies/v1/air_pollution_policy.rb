# frozen_string_literal: true

module V1
  class AirPollutionPolicy < ApplicationPolicy
    def create?
      true
    end
  end
end
