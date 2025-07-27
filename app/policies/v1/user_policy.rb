# frozen_string_literal: true

module V1
  class UserPolicy < ApplicationPolicy
    def show?
      user.present? && [ record.id, record.doctor_id ].include?(user.id)
    end

    def create?
      true
    end

    def destroy?
      record.doctor_id == user.id
    end
  end
end
