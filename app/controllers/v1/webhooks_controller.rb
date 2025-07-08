module V1
  class WebhooksController < ActionController::API
    def garmin
      head :created
  rescue JSON::ParserError
    head :bad_request
    end
  end
end
