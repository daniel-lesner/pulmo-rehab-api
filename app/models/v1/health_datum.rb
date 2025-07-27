# frozen_string_literal: true

module V1
  class HealthDatum < ApplicationRecord
    belongs_to :user
  end
end
