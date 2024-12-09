# frozen_string_literal: true

module V1
  class Bracelet < ApplicationRecord
    belongs_to :user

    validates :name, :brand, :api_key, presence: true
    # validates :api_key, uniqueness: true
    # validates :brand, inclusion: { in: [ :garmin, :xiaomi, :huawei ] }

    before_create :set_user

    def set_user
    end
  end
end
