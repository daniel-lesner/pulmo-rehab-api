# frozen_string_literal: true

module V1
  class DashboardResource < PoroResource
    model_name "V1::Dashboard"

    attributes :bracelet_id, :bracelet_type, :date, :data_type, :data, :time_interval_in_minutes

    def fetchable_fields
      super - [ :password ]
    end

    def save
      bracelet = V1::Bracelet.find(bracelet_id)

      searched_date = Time.utc(*date.split("-").map(&:to_i)).to_i

      service = case bracelet.brand
      when "Fitbit"
        FitbitService.new(
          metric: data_type,
          date: searched_date,
          access_token: bracelet.token,
          refresh_token: bracelet.token_secret,
          bracelet_id: bracelet.id
        )
      when "Garmin"
        GarminService.new(
          metric: data_type,
          date: searched_date,
          time_interval_in_minutes: time_interval_in_minutes,
          token: bracelet.token,
          token_secret: bracelet.token_secret
        )
      else
        raise "Unsupported bracelet type: #{bracelet.type}"
      end

      response = service.call

      @model.data = response

      context[:created_model] = @model
    end
  end
end
