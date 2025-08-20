# frozen_string_literal: true

module V1
  class LocalAirPollutionPolicy < ApplicationPolicy
    def create?
      true
    end
  end
end
