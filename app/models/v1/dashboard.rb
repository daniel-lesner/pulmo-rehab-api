# frozen_string_literal: true

module V1
  class Dashboard < VirtualRecord
    attr_accessor :id, :user_id, :heart_rate, :stress, :spo2, :respiration
  end
end
