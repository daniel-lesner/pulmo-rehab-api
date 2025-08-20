# frozen_string_literal: true

module V1
  class LocalAirPollution < VirtualRecord
    attr_accessor :id, :device_id, :dt
    attr_accessor :pm2_5, :pm10, :pm1, :pm0_3
    attr_accessor :co, :co2, :tvoc, :hcho
    attr_accessor :temperature_c, :humidity, :battery_percentage, :charging
    attr_accessor :aqi_level, :aqi_label
  end
end
