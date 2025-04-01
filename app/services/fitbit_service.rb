# frozen_string_literal: true

class FitbitService
  URL = "https://api.fitbit.com/oauth2/token"

  def initialize(metric:, date:, access_token:, refresh_token:, bracelet_id:)
    @metric = metric
    @date = Time.at(date).strftime("%Y-%m-%d")
    @access_token = access_token
    @refresh_token = refresh_token
    @user_id = sub = JWT.decode(access_token, nil, false).dig(0, "sub")
    @bracelet_id = bracelet_id
  end

  def call
    data = case @metric
    when "sleep"
      get_sleep_data()
    else
      raise "Unknown metric"
    end

    data
  end

  def self.exchange_auth_code(auth_code)
    uri = URI(URL)
    request = Net::HTTP::Post.new(uri)
    request.basic_auth(ENV["FITBIT_CLIENT_ID"],  ENV["FITBIT_CLIENT_SECRET"])
    request.set_form_data({
      grant_type: "authorization_code",
      code: auth_code,
      redirect_uri: ENV["FITBIT_REDIRECT_URI"]
    })

    response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.request(request) }

    JSON.parse(response.body)
  end

  private

    def fetch_fitbit_data(url)
      uri = URI(url)
      request = Net::HTTP::Get.new(uri)
      request["Authorization"] = "Bearer #{@access_token}"

      response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.request(request) }
      parsed_response = JSON.parse(response.body)

      if parsed_response["errors"]&.any? { |e| e["errorType"] == "invalid_token" }
        refresh_access_token

        return fetch_fitbit_data(url)
      end

      parsed_response
    end

    def refresh_access_token
      uri = URI(URL)
      request = Net::HTTP::Post.new(uri)
      request.basic_auth(ENV["FITBIT_CLIENT_ID"],  ENV["FITBIT_CLIENT_SECRET"])
      request.set_form_data(
        grant_type: "refresh_token",
        refresh_token: @refresh_token
      )

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(request) }
      parsed_response = JSON.parse(response.body)

      @access_token  = parsed_response["access_token"]
      @refresh_token = parsed_response["refresh_token"]

      bracelet = V1::Bracelet.find(@bracelet_id)
      bracelet.update!(token: @access_token, token_secret: @refresh_token)
    end

    def get_sleep_data
      url = "https://api.fitbit.com/1.2/user/#{@user_id}/sleep/date/#{@date}.json"
      response = fetch_fitbit_data(url)

      response
    end
end
