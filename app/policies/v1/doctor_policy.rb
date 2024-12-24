# frozen_string_literal: true

module V1
  class DoctorPolicy < ApplicationPolicy
    def show?
      user.present? && (record.id == user.id)
    end

    def create?
      true
    end
  end
end
