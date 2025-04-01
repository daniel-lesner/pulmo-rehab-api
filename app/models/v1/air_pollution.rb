# frozen_string_literal: true

module V1
  class AirPollution < VirtualRecord
    attr_accessor :id, :lat, :lon, :co, :no, :no2, :o3, :so2, :pm2_5, :pm10, :nh3, :dt
  end
end
