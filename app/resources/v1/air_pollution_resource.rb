# frozen_string_literal: true

module V1
  class AirPollutionResource < PoroResource
    model_name "V1::AirPollution"

    attributes :lat, :lon, :co, :no, :no2, :o3, :so2, :pm2_5, :pm10, :nh3, :dt

    def save
      context[:created_model] = @model
    end

    def save
      api_key = ENV["OPENWEATHERMAP_API_KEY"]
      end_time = Time.now
      start_time = end_time - 24.hours

      uri = URI("http://api.openweathermap.org/data/2.5/air_pollution/history?lat=#{lat}&lon=#{lon}&start=#{start_time.to_i}&end=#{end_time.to_i}&appid=#{api_key}")

      response = Net::HTTP.get(uri)
      result = JSON.parse(response)

      components = result["list"] || []

      peak = components.each_with_object({}) do |item, memo|
        item["components"].each do |key, value|
          memo[key] = [ memo[key] || 0, value ].max
        end
      end

      @model.co = peak["co"]
      @model.no = peak["no"]
      @model.no2 = peak["no2"]
      @model.o3 = peak["o3"]
      @model.so2 = peak["so2"]
      @model.pm2_5 = peak["pm2_5"]
      @model.pm10 = peak["pm10"]
      @model.nh3 = peak["nh3"]
      @model.dt = end_time.to_i

      context[:created_model] = @model
    end
  end
end
