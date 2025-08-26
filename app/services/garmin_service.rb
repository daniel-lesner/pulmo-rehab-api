# frozen_string_literal: true

class GarminService
  EPOCHS_SEDENTARY_ALLOWED_GAPS = [ 15, 900 ].freeze

  PATH_MAPPING = {
    "stats"            => "dailies",
    "heartRate"        => "dailies",
    "hrv"              => "hrv",
    "spo2"             => "pulseOx",
    "respiration"      => "respiration",
    "stress"           => "stressDetails",
    "bodyBatteryLevel" => "stressDetails",
    "activities"       => "activities",
    "moveiq"           => "moveiq",
    "epochs"           => "epochs",
    "fitnessAge"       => "userMetrics",
    "sleep"            => "sleeps"
  }.freeze

  DATA_COLUMN_NAME_MAPPING = {
    "stats"            => "timeOffsetHeartRateSamples",
    "heartRate"        => "timeOffsetHeartRateSamples",
    "hrv"              => "hrvValues",
    "spo2"             => "timeOffsetSpo2Values",
    "stress"           => "timeOffsetStressLevelValues",
    "bodyBatteryLevel" => "timeOffsetBodyBatteryValues"
  }.freeze

  def initialize(metric:, date:, time_interval_in_minutes:, token:, token_secret:)
    @metric                   = metric
    @api_base_url             = "https://apis.garmin.com/wellness-api/rest/#{PATH_MAPPING[metric]}".freeze
    @data_column_name         = DATA_COLUMN_NAME_MAPPING[metric]
    @time_interval_in_minutes = time_interval_in_minutes
    @consumer_key             = ENV["GARMIN_CONSUMER_KEY"]
    @consumer_secret          = ENV["GARMIN_CONSUMER_SECRET"]
    @token                    = token
    @token_secret             = token_secret

    @start_time   = date - 86_400
    @end_time     = date
    @searched_date = date
  end

  def call
    searched_date_str = Time.at(@end_time).strftime("%Y-%m-%d")

    if @metric == "fitnessAge"
      result_raw = request_data(@start_time + 86_400, @end_time + 86_400)
      next_raw   = request_data(@start_time + 172_800, @end_time + 172_800)

      result = array_or_empty(result_raw).select { |e| e.is_a?(Hash) && e["calendarDate"] == searched_date_str }
      next_day_result = array_or_empty(next_raw).select { |e| e.is_a?(Hash) && e["calendarDate"] == searched_date_str }

      aggregated = result + next_day_result
      return [] if aggregated.empty?

      return { "fitnessAge" => aggregated[0]["fitnessAge"] }
    end

    if [ "moveiq", "sleep" ].include?(@metric)
      today_raw = request_data(@start_time, @end_time)
      next_raw  = request_data(@start_time + 86_400, @end_time + 86_400)

      result = array_or_empty(today_raw).select { |e| e.is_a?(Hash) && e["calendarDate"] == searched_date_str }
      next_day_result = array_or_empty(next_raw).select { |e| e.is_a?(Hash) && e["calendarDate"] == searched_date_str }

      aggregated = result + next_day_result

      if @metric == "sleep"
        return [] if aggregated.empty?

        sleep_day = aggregated[0]

        start_time = sleep_day["startTimeInSeconds"].to_i + sleep_day["startTimeOffsetInSeconds"].to_i

        convert_to_time_format = lambda do |base_time, offset_seconds|
          Time.at(base_time + offset_seconds).utc.strftime("%H:%M")
        end

        if sleep_day["timeOffsetSleepSpo2"].is_a?(Hash)
          updated_spo2 = {}
          sleep_day["timeOffsetSleepSpo2"].each do |k, v|
            updated_spo2[convert_to_time_format.call(start_time, k.to_i)] = v
          end
          sleep_day["timeOffsetSleepSpo2"] = updated_spo2
        end

        if sleep_day["timeOffsetSleepRespiration"].is_a?(Hash)
          updated_resp = {}
          sleep_day["timeOffsetSleepRespiration"].each do |k, v|
            updated_resp[convert_to_time_format.call(start_time, k.to_i)] = v
          end
          sleep_day["timeOffsetSleepRespiration"] = updated_resp
        end

        return sleep_day
      end

      return aggregated
    end

    if [ "epochs", "activities" ].include?(@metric)
      r1 = array_or_empty(request_data(@start_time, @end_time))
             .select { |e| e.is_a?(Hash) && in_day_window?(e) }
      r2 = array_or_empty(request_data(@start_time + 86_400, @end_time + 86_400))
             .select { |e| e.is_a?(Hash) && in_day_window?(e) }

      return aggreggate_sedentary_epochs(r1 + r2)
    end

    if @metric == "respiration"
      today = array_or_empty(request_data(@start_time, @end_time))
                .select { |e| e.is_a?(Hash) && in_day_window?(e) }
      nxt   = array_or_empty(request_data(@start_time + 86_400, @end_time + 86_400))
                .select { |e| e.is_a?(Hash) && in_day_window?(e) }

      out = {}
      (today + nxt).each do |entry|
        base_time = entry["startTimeInSeconds"].to_i + entry["startTimeOffsetInSeconds"].to_i
        series = entry["timeOffsetEpochToBreaths"].is_a?(Hash) ? entry["timeOffsetEpochToBreaths"] : {}
        series.each do |offset, breath_rate|
          timestamp = Time.at(base_time + offset.to_i).utc.strftime("%H:%M")
          out[timestamp] = breath_rate
        end
      end
      return out
    end

    response = nil
    while @end_time < (Time.now + 86_400).to_i
      raw = request_data(@start_time, @end_time)
      response = array_or_empty(raw)

      if response.empty? || !response.any? { |e| e.is_a?(Hash) && e["calendarDate"] == searched_date_str }
        @start_time += 86_400
        @end_time   += 86_400
      else
        break
      end
    end

    return [] if response.nil? || response.empty?

    result = response
      .select { |e| e.is_a?(Hash) && e["calendarDate"] == searched_date_str && column_present?(e) }
      .max_by { |e| e[@data_column_name].size }

    next_day_response = array_or_empty(request_data(@start_time + 86_400, @end_time + 86_400))
    next_day_result = next_day_response
      .select { |e| e.is_a?(Hash) && e["calendarDate"] == searched_date_str && column_present?(e) }
      .max_by { |e| e[@data_column_name].size }

    if result
      pick = if next_day_result && result[@data_column_name].size <= next_day_result[@data_column_name].size
        next_day_result
      else
        result
      end
      create_interval(pick, @time_interval_in_minutes)
    elsif next_day_result
      create_interval(next_day_result, @time_interval_in_minutes)
    else
      []
    end
  end

  private

    def array_or_empty(data)
      data.is_a?(Array) ? data : []
    end

    def in_day_window?(entry)
      s = entry["startTimeInSeconds"].to_i
      s > @searched_date && s < (@searched_date + 86_400)
    end

    def column_present?(entry)
      col = @data_column_name
      return false if col.nil?
      entry[col].is_a?(Hash) && !entry[col].empty?
    end

    def create_interval(data, interval)
      return generate_empty_ranges(interval) if @data_column_name && data[@data_column_name].is_a?(Hash) && data[@data_column_name].empty?

      if @metric == "hrv"
        start_time = Time.at(data["startTimeInSeconds"]).strftime("%H:%M")
        result = {}
        current_time = Time.parse(start_time)
        (data["hrvValues"] || {}).each do |_offset, value|
          label = current_time.strftime("%H:%M")
          result[label] = value
          current_time += 5 * 60
        end
        return result
      end

      if @metric == "stats"
        return data.reject { |k, _|
          [ "summaryId", "calendarDate", "activityType", "timeOffsetHeartRateSamples" ].include?(k)
        }
      end

      interval_in_seconds = interval.to_i * 60
      sums = Hash.new { |h, k| h[k] = { sum: 0, count: 0 } }

      series = @data_column_name ? (data[@data_column_name] || {}) : {}
      series.each do |offset, rate|
        r = rate.to_f
        next if r <= 0
        idx = offset.to_i / interval_in_seconds
        sums[idx][:sum]   += r
        sums[idx][:count] += 1
      end

      max_index = (24 * 60) / interval.to_i - 1
      (0..max_index).each_with_object({}) do |i, hash|
        start_h, start_m = (i * interval.to_i).divmod(60)
        end_h,   end_m   = ((i + 1) * interval.to_i).divmod(60)
        label            = "#{start_h}:#{start_m.to_s.rjust(2, '0')}-#{end_h}:#{end_m.to_s.rjust(2, '0')}"
        c                = sums[i][:count]
        hash[label]      = c.positive? ? (sums[i][:sum].to_f / c).round(2) : 0
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
        "oauth_consumer_key"     => @consumer_key,
        "oauth_token"            => @token,
        "oauth_nonce"            => SecureRandom.hex(16),
        "oauth_timestamp"        => Time.now.to_i.to_s,
        "oauth_signature_method" => "HMAC-SHA1",
        "oauth_version"          => "1.0"
      }
    end

    def generate_oauth_signature(http_method, base_url, query_params, oauth_params)
      all_params     = oauth_params.merge(query_params)
      encoded_params = all_params.sort.map { |k, v| "#{CGI.escape(k.to_s)}=#{CGI.escape(v.to_s)}" }.join("&")
      base_string    = "#{http_method}&#{CGI.escape(base_url)}&#{CGI.escape(encoded_params)}"
      signing_key    = "#{CGI.escape(@consumer_secret)}&#{CGI.escape(@token_secret)}"

      hashed = OpenSSL::HMAC.digest("sha1", signing_key, base_string)
      Base64.strict_encode64(hashed).strip
    end

    def build_authorization_header(oauth_params)
      "OAuth " + oauth_params.map { |k, v| "#{CGI.escape(k.to_s)}=\"#{CGI.escape(v.to_s)}\"" }.join(", ")
    end

    def request_data(start_time, end_time)
      query_params = {
        "uploadStartTimeInSeconds" => start_time,
        "uploadEndTimeInSeconds"   => end_time
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
    rescue => e
      Rails.logger.warn("[GarminService] HTTP error: #{e.class}: #{e.message}")
      []
    end

    def parse_response(response)
      code = response.code.to_i
      if code == 200
        json = JSON.parse(response.body)
        json.is_a?(Array) ? json : []
      else
        Rails.logger.warn("[GarminService] HTTP #{code}: #{response.message} - #{response.body.to_s[0, 200]}")
        []
      end
    rescue JSON::ParserError => e
      Rails.logger.warn("[GarminService] JSON parse error: #{e.message}")
      []
    end

    def aggreggate_sedentary_epochs(entries)
      merged = array_or_empty(entries).select { |e| e.is_a?(Hash) }.sort_by { |e| e["startTimeInSeconds"].to_i }

      compressed = []
      current_group = nil
      sum_active_time = 0
      sum_duration = 0
      prev_sedentary_start = nil

      flush_group = lambda do
        if current_group
          current_group["activeTimeInSeconds"] = sum_active_time
          current_group["durationInSeconds"]   = sum_duration
          compressed << current_group
        end
        current_group = nil
        sum_active_time = 0
        sum_duration = 0
      end

      merged.each do |entry|
        if entry["activityType"] == "SEDENTARY"
          if current_group.nil?
            current_group = entry.dup
            sum_active_time       = entry["activeTimeInSeconds"].to_i
            sum_duration          = entry["durationInSeconds"].to_i
            prev_sedentary_start  = entry["startTimeInSeconds"].to_i
          else
            gap = entry["startTimeInSeconds"].to_i - prev_sedentary_start
            if EPOCHS_SEDENTARY_ALLOWED_GAPS.include?(gap)
              sum_active_time      += entry["activeTimeInSeconds"].to_i
              sum_duration         += entry["durationInSeconds"].to_i
              prev_sedentary_start  = entry["startTimeInSeconds"].to_i
            else
              flush_group.call
              current_group         = entry.dup
              sum_active_time       = entry["activeTimeInSeconds"].to_i
              sum_duration          = entry["durationInSeconds"].to_i
              prev_sedentary_start  = entry["startTimeInSeconds"].to_i
            end
          end
        else
          flush_group.call
          compressed << entry
        end
      end

      flush_group.call
      compressed
    end
end
