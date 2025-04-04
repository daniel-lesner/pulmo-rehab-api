# frozen_string_literal: true

class GarminService
  PATH_MAPPING = {
    "stats" => "dailies",
    "heartRate" => "dailies",
    "hrv" => "hrv",
    "spo2" => "pulseOx",
    "respiration" => "respiration",
    "stress" => "stressDetails",
    "bodyBatteryLevel" => "stressDetails",
    "activities" => "activities",
    "moveiq" => "moveiq",
    "epochs" => "epochs",
    "fitnessAge" => "userMetrics",
    "sleep" => "sleeps"
  }

  DATA_COLUMN_NAME_MAPPING = {
    "stats" => "timeOffsetHeartRateSamples",
    "heartRate" => "timeOffsetHeartRateSamples",
    "hrv" => "hrvValues",
    "spo2" => "timeOffsetSpo2Values",
    "stress" => "timeOffsetStressLevelValues",
    "bodyBatteryLevel" => "timeOffsetBodyBatteryValues"
  }

  def initialize(metric:, date:, time_interval_in_minutes:, token:, token_secret:)
    @metric = metric
    @api_base_url = "https://apis.garmin.com/wellness-api/rest/#{PATH_MAPPING[metric]}".freeze
    @data_column_name = DATA_COLUMN_NAME_MAPPING[metric]
    @time_interval_in_minutes = time_interval_in_minutes
    @consumer_key = ENV["GARMIN_CONSUMER_KEY"]
    @consumer_secret = ENV["GARMIN_CONSUMER_SECRET"]
    @token = token
    @token_secret = token_secret
    @start_time = date - 86400
    @end_time = date
    @searched_date = date
  end

  def call
    searched_date = Time.at(@end_time).strftime("%Y-%m-%d")

    if @metric == "fitnessAge"
      result = request_data(@start_time + 86400, @end_time + 86400)
      .select { |entry| entry["calendarDate"] == searched_date }

      next_day_result = request_data(@start_time + 86400 * 2, @end_time + 86400 * 2)
      .select { |entry| entry["calendarDate"] == searched_date }

      aggreggated_result = result + next_day_result

      return [] if aggreggated_result.empty?

      return {
        "fitnessAge" => aggreggated_result[0]["fitnessAge"]
      }
    end

    if [ "moveiq", "sleep" ].include?(@metric)
      result = request_data(@start_time, @end_time)
      .select { |entry| entry["calendarDate"] == searched_date }

      next_day_result = request_data(@start_time + 86400, @end_time + 86400)
      .select { |entry| entry["calendarDate"] == searched_date }

      aggreggated_result = result + next_day_result

      if @metric == "sleep"
        aggreggated_result = aggreggated_result[0]

        start_time = aggreggated_result["startTimeInSeconds"] + aggreggated_result["startTimeOffsetInSeconds"]

        def convert_to_time_format(base_time, offset_seconds)
          time = Time.at(base_time + offset_seconds).utc.strftime("%H:%M")
          time
        end

        updated_spo2 = {}
        aggreggated_result["timeOffsetSleepSpo2"].each do |key, value|
          time_key = convert_to_time_format(start_time, key.to_i)
          updated_spo2[time_key] = value
        end

        updated_respiration = {}
        aggreggated_result["timeOffsetSleepRespiration"].each do |key, value|
          time_key = convert_to_time_format(start_time, key.to_i)
          updated_respiration[time_key] = value
        end

        aggreggated_result["timeOffsetSleepSpo2"] = updated_spo2
        aggreggated_result["timeOffsetSleepRespiration"] = updated_respiration
      end

      return aggreggated_result
    end

    if [ "epochs", "activities" ].include?(@metric)
      result = request_data(@start_time, @end_time).select do |entry|
        entry["startTimeInSeconds"] > @searched_date && entry["startTimeInSeconds"] < @searched_date + 86400
      end

      next_day_result = request_data(@start_time + 86400, @end_time + 86400).select do |entry|
        entry["startTimeInSeconds"] > @searched_date && entry["startTimeInSeconds"] < @searched_date + 86400
      end

      return result + next_day_result
    end

    if @metric == "respiration"
      today_result = request_data(@start_time, @end_time).select do |entry|
        entry["startTimeInSeconds"] > @searched_date && entry["startTimeInSeconds"] < @searched_date + 86400
      end

      next_day_result = request_data(@start_time + 86400, @end_time + 86400).select do |entry|
        entry["startTimeInSeconds"] > @searched_date && entry["startTimeInSeconds"] < @searched_date + 86400
      end

      result = {}

      aggreggated_result = today_result + next_day_result

      aggreggated_result.each do |entry|
        base_time = entry["startTimeInSeconds"] + entry["startTimeOffsetInSeconds"]

        entry["timeOffsetEpochToBreaths"].each do |offset, breath_rate|
          timestamp = Time.at(base_time + offset.to_i).utc.strftime("%H:%M")
          result[timestamp] = breath_rate
        end
      end

      return result
    end

    while @end_time < (Time.now + 1.day).to_i
      response = request_data(@start_time, @end_time)

      if response.empty? || !response.any? { |entry| entry["calendarDate"] == searched_date }
        @start_time += 86400
        @end_time += 86400
      else
        break
      end
    end

    return [] if response.empty?

    result = response
    .select { |entry| entry["calendarDate"] == searched_date && !entry[@data_column_name].empty? }
    .max_by { |entry| entry[@data_column_name].size }

    next_day_result = request_data(@start_time + 86400, @end_time + 86400)
    .select { |entry| entry["calendarDate"] == searched_date && !entry[@data_column_name].empty? }
    .max_by { |entry| entry[@data_column_name].size }

    if result
      create_interval(
        next_day_result && result[@data_column_name].size <= next_day_result[@data_column_name].size ? next_day_result : result,
        @time_interval_in_minutes
      )
    elsif next_day_result
      create_interval(
        next_day_result,
        @time_interval_in_minutes
      )
    else
      []
    end
  end

  private

    def create_interval(data, interval)
      return generate_empty_ranges(interval) if data[@data_column_name].empty?

      if @metric == "hrv"
        start_time = Time.at(data["startTimeInSeconds"]).strftime("%H:%M")
        result = {}
        current_time = Time.parse(start_time)

        data["hrvValues"].each do |offset, value|
          label = current_time.strftime("%H:%M")
          result[label] = value
          current_time += 5 * 60
        end

        return result
      end

      if @metric == "stats"
        return data.reject { |key, _| [ "summaryId", "calendarDate", "activityType", "timeOffsetHeartRateSamples" ].include?(key) }
      end

      interval_in_seconds = interval.to_i * 60
      sums = Hash.new { |h, k| h[k] = { sum: 0, count: 0 } }

      data[@data_column_name].each do |offset, rate|
        next if rate <= 0
        idx = offset.to_i / interval_in_seconds
        sums[idx][:sum] += rate
        sums[idx][:count] += 1
      end

      max_index = (24 * 60) / interval.to_i - 1

      (0..max_index).each_with_object({}) do |i, hash|
        start_h, start_m = (i * interval.to_i).divmod(60)
        end_h,   end_m   = ((i + 1) * interval.to_i).divmod(60)
        label            = "#{start_h}:#{start_m.to_s.rjust(2, '0')}-#{end_h}:#{end_m.to_s.rjust(2, '0')}"
        c                = sums[i][:count]
        hash[label]      = c > 0 ? (sums[i][:sum].to_f / c).round(2) : 0
      end
    end

    def generate_empty_ranges(interval)
      max_index = (24 * 60) / interval.to_i - 1

      (0..max_index).each_with_object({}) do |i, hash|
        start_h, start_m = (i * interval.to_i).divmod(60)
        end_h,   end_m   = ((i + 1) * interval.to_i).divmod(60)
        hash["#{start_h}:#{start_m.to_s.rjust(2, '0')}-#{end_h}:#{end_m.to_s.rjust(2, '0')}"] = 0
      end
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

    def request_data(start_time, end_time)
      query_params = {
        "uploadStartTimeInSeconds" => start_time,
        "uploadEndTimeInSeconds" => end_time
      }

      oauth_params = generate_oauth_params

      signature = generate_oauth_signature("GET", @api_base_url, query_params, oauth_params)
      oauth_params["oauth_signature"] = signature

      authorization_header = build_authorization_header(oauth_params)

      make_request(@api_base_url, query_params, authorization_header)
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
