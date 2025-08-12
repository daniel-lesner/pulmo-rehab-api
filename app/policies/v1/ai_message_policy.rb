# frozen_string_literal: true

module V1
  class AiMessagePolicy < ApplicationPolicy
    def create?
      true
    end
  end
end
