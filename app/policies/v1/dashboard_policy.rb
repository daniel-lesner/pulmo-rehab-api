# frozen_string_literal: true

module V1
  class DashboardPolicy < ApplicationPolicy
    def create?
      true
    end
  end
end
