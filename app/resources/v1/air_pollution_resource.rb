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
      uri = URI("http://api.openweathermap.org/data/2.5/air_pollution?lat=#{lat}&lon=#{lon}&appid=#{api_key}")

      response = Net::HTTP.get(uri)
      result = JSON.parse(response)

      components = result.dig("list", 0, "components")
      timestamp = result.dig("list", 0, "dt")

      @model.co     = components["co"]
      @model.no     = components["no"]
      @model.no2    = components["no2"]
      @model.o3     = components["o3"]
      @model.so2    = components["so2"]
      @model.pm2_5  = components["pm2_5"]
      @model.pm10   = components["pm10"]
      @model.nh3    = components["nh3"]
      @model.dt     = timestamp

      context[:created_model] = @model
    end
  end
end
