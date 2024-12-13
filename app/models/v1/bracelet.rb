# frozen_string_literal: true

module V1
  class Bracelet < ApplicationRecord
    belongs_to :user

    validates :name, :brand, :api_key, presence: true
    # validates :api_key, uniqueness: true
    # validates :brand, inclusion: { in: [ :garmin, :xiaomi, :huawei ] }
  end
end
