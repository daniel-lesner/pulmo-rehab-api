# frozen_string_literal: true

module V1
  class BraceletPolicy < ApplicationPolicy
    def show?
      user.present? && (record.user.id == user.id)
    end

    def create?
      true
    end

    def index?
      true
    end

    def destroy?
      user.present? && (record.user.id == user.id)
    end
  end
end
