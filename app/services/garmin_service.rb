# frozen_string_literal: true

class GarminService
  PATH_MAPPING = {
    "heartRate" => "dailies"
  }
  def initialize(metric:, date:, token:, token_secret:)
    @api_base_url = "https://apis.garmin.com/wellness-api/rest/#{PATH_MAPPING[metric]}".freeze
    @consumer_key = ENV["GARMIN_CONSUMER_KEY"]
    @consumer_secret = ENV["GARMIN_CONSUMER_SECRET"]
    @token = token
    @token_secret = token_secret
    @start_time = date - 86400
    @end_time = date
  end

  def call
    searched_date = Time.at(@end_time).strftime("%Y-%m-%d")

    while @end_time < Time.now.to_i
      query_params = {
        "uploadStartTimeInSeconds" => @start_time,
        "uploadEndTimeInSeconds" => @end_time
      }

      oauth_params = generate_oauth_params

      signature = generate_oauth_signature("GET", @api_base_url, query_params, oauth_params)
      oauth_params["oauth_signature"] = signature

      authorization_header = build_authorization_header(oauth_params)

      response = make_request(@api_base_url, query_params, authorization_header)

      if response.empty? || !response.any? { |entry| entry["calendarDate"] == searched_date }
        @start_time += 86400
        @end_time += 86400
      else
        break
      end
    end

    return [] if response.empty?

    result = response
    .select { |entry| entry["calendarDate"] == searched_date && !entry["timeOffsetHeartRateSamples"].empty? }
    .max_by { |entry| entry["timeOffsetHeartRateSamples"].size }

    if result
      calculate_hourly_heart_rate(result)
    else
      []
    end
  end

  private

    def calculate_hourly_heart_rate(data)
      seconds_in_hour = 3600

      hourly_averages = Hash.new(0)

      heart_rate_samples = data["timeOffsetHeartRateSamples"]

      return (0..23).each_with_object({}) do |hour, hash|
        range_key = "#{hour}-#{hour + 1}:00"
        hash[range_key] = 0
      end if heart_rate_samples.empty?

      hourly_sums = Hash.new { |hash, key| hash[key] = { sum: 0, count: 0 } }

      heart_rate_samples.each do |time_offset, heart_rate|
        hour = time_offset.to_i / seconds_in_hour

        hourly_sums[hour][:sum] += heart_rate
        hourly_sums[hour][:count] += 1
      end

      (0..23).each do |hour|
        range_key = "#{hour}-#{hour + 1}:00"
        if hourly_sums[hour][:count] > 0
          hourly_averages[range_key] = (hourly_sums[hour][:sum].to_f / hourly_sums[hour][:count]).round(2)
        else
          hourly_averages[range_key] = 0
        end
      end

      hourly_averages
    end


    def generate_oauth_params
      {
        "oauth_consumer_key" => @consumer_key,
        "oauth_token" => @token,
        "oauth_nonce" => SecureRandom.hex(16),
        "oauth_timestamp" => Time.now.to_i.to_s,
        "oauth_signature_method" => "HMAC-SHA1",
        "oauth_version" => "1.0"
      }
    end

    def generate_oauth_signature(http_method, base_url, query_params, oauth_params)
      all_params = oauth_params.merge(query_params)
      encoded_params = all_params.sort.map { |k, v| "#{CGI.escape(k.to_s)}=#{CGI.escape(v.to_s)}" }.join("&")

      base_string = "#{http_method}&#{CGI.escape(base_url)}&#{CGI.escape(encoded_params)}"

      signing_key = "#{CGI.escape(@consumer_secret)}&#{CGI.escape(@token_secret)}"

      hashed = OpenSSL::HMAC.digest("sha1", signing_key, base_string)
      Base64.strict_encode64(hashed).strip
    end

    def build_authorization_header(oauth_params)
      "OAuth " + oauth_params.map { |k, v| "#{CGI.escape(k.to_s)}=\"#{CGI.escape(v.to_s)}\"" }.join(", ")
    end

    def make_request(base_url, query_params, authorization_header)
      uri = URI(base_url)
      uri.query = URI.encode_www_form(query_params)

      https = Net::HTTP.new(uri.host, uri.port)
      https.use_ssl = true

      request = Net::HTTP::Get.new(uri)
      request["Authorization"] = authorization_header

      response = https.request(request)
      parse_response(response)
    end

    def parse_response(response)
      if response.code.to_i == 200
        JSON.parse(response.body)
      else
        { error: "HTTP #{response.code}", message: response.message, body: response.body }
      end
    end
end
