# frozen_string_literal: true

module V1
  class LocalAirPollutionResource < PoroResource
    model_name "V1::LocalAirPollution"

    attributes :device_id, :dt,
               :pm2_5, :pm10, :pm1, :pm0_3,
               :co, :co2, :tvoc, :hcho,
               :temperature_c, :humidity, :battery_percentage, :charging,
               :aqi_level, :aqi_label

    def save
      device_id = @model.device_id.presence || ENV["TUYA_DEFAULT_DEVICE_ID"]
      raise "Missing device_id" unless device_id

      status_list = TuyaAirPollutionService.new.device_status(device_id)
      lookup = status_list.to_h { |h| [ h["code"], h ] }

      get = ->(code) { lookup.dig(code, "value") }

      @model.temperature_c     = (get.call("temp_current")     || 0).to_f
      @model.humidity          = (get.call("humidity_value")   || 0).to_f
      @model.co2               = (get.call("co2_value")        || 0).to_f
      @model.tvoc              = (get.call("tvoc_value")       || 0).to_f
      @model.hcho              = (get.call("ch2o_value")       || 0).to_f
      @model.pm2_5             = (get.call("pm2_5") || get.call("pm25") || get.call("pm25_value") || 0).to_f
      @model.pm10              = (get.call("pm10")  || 0).to_f
      @model.pm1               = (get.call("pm1")   || 0).to_f
      @model.pm0_3             = (get.call("pm03")  || 0).to_f
      @model.co                = (get.call("co_value") || get.call("co") || 0).to_f
      @model.battery_percentage = (get.call("battery_percentage") || 0).to_f
      @model.charging           = !!get.call("charge_state")

      aqi_raw   = get.call("air_quality_index")
      @model.aqi_level = case aqi_raw
      when /\Alevel_(\d)\z/ then Regexp.last_match(1).to_i
      else nil
      end
      @model.aqi_label = case @model.aqi_level
      when 1 then "Good"
      when 2 then "Moderate"
      when 3 then "Sensitive"
      when 4 then "Unhealthy"
      when 5 then "Very Unhealthy"
      else nil
      end

      @model.dt ||= Time.now.to_i
      @model.id ||= "#{device_id}-#{@model.dt}"

      context[:status] = :created
      context[:created_model] = @model
  rescue => e
    Rails.logger.error("[LocalAirPollutionResource] #{e.class}: #{e.message}")

    @model.pm2_5 = @model.pm10 = @model.pm1 = @model.pm0_3 = 0.0
    @model.co = @model.co2 = @model.tvoc = @model.hcho = 0.0
    @model.temperature_c = @model.humidity = 0.0
    @model.battery_percentage = 0.0
    @model.charging = false
    @model.aqi_level = @model.aqi_label = nil
    @model.dt ||= Time.now.to_i
    @model.id ||= "fallback-#{@model.dt}"

    context[:status] = :created
    context[:created_model] = @model
    end
  end
end
