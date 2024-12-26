# frozen_string_literal: true

module V1
  class DashboardResource < PoroResource
    model_name "V1::Dashboard"

    attributes :bracelet_id, :bracelet_type, :date, :data_type, :data

    def fetchable_fields
      super - [ :password ]
    end

    def save
      bracelet = V1::Bracelet.find(bracelet_id)

      searched_date = Time.utc(*date.split("-").map(&:to_i)).to_i

      service = GarminService.new(
        metric: data_type,
        date: searched_date,
        token: bracelet.token,
        token_secret: bracelet.token_secret,
      )

      response = service.call

      @model.data = response

      context[:created_model] = @model
    end
  end
end
