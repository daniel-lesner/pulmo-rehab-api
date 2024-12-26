# frozen_string_literal: true

module V1
  class Bracelet < ApplicationRecord
    belongs_to :user

    validates :name, :brand, :token, :token_secret, presence: true
    # validates :token, uniqueness: true
    # validates :brand, inclusion: { in: [ :garmin, :xiaomi, :huawei ] }
  end
end
