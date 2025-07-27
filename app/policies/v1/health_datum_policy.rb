# frozen_string_literal: true

module V1
  class HealthDatumPolicy < ApplicationPolicy
    def show?
      true
    end

    def create?
      true
    end

    def update?
      false
    end

    def destroy?
      true
    end
  end
end
