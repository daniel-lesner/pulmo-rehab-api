# frozen_string_literal: true

require "net/http"
require "json"
require "openssl"
require "securerandom"

class TuyaAirPollution
  class Error < StandardError; end

  HOST      = ENV.fetch("TUYA_HOST", "https://openapi.tuyaeu.com")
  CLIENT_ID = ENV.fetch("TUYA_CLIENT_ID")
  SECRET    = ENV.fetch("TUYA_SECRET")

  def device_status(device_id)
    token = get_token
    path  = "/v1.0/devices/#{device_id}/status"
    uri   = URI(HOST + path)

    req = Net::HTTP::Get.new(uri)
    build_headers(path, access_token: token).each { |k, v| req[k] = v }

    body = perform!(uri, req)
    ensure_success!(body, "Device status error")
    body["result"]
  end

  private

    def get_token
      path = "/v1.0/token?grant_type=1"
      uri  = URI(HOST + path)
      req  = Net::HTTP::Get.new(uri)
      build_headers(path).each { |k, v| req[k] = v }

      body = perform!(uri, req)
      ensure_success!(body, "Token error")
      body.dig("result", "access_token")
    end

    def build_headers(path, method: "GET", body: "", access_token: nil)
      t            = (Time.now.to_f * 1000).to_i.to_s
      nonce        = SecureRandom.uuid
      content_hash = OpenSSL::Digest::SHA256.hexdigest(body.to_s)
      string_to_sign = [ method, content_hash, "", path ].join("\n")
      base = if access_token
        CLIENT_ID + access_token + t + nonce + string_to_sign
      else
        CLIENT_ID + t + nonce + string_to_sign
      end
      sign = OpenSSL::HMAC.hexdigest("SHA256", SECRET, base).upcase

      headers = {
        "client_id"   => CLIENT_ID,
        "sign_method" => "HMAC-SHA256",
        "t"           => t,
        "nonce"       => nonce,
        "sign"        => sign
      }
      headers["access_token"] = access_token if access_token
      headers
    end

    def perform!(uri, req)
      res = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") { |h| h.request(req) }
      JSON.parse(res.body)
    rescue JSON::ParserError
      { "success" => false, "errorMsg" => "Bad JSON from Tuya" }
    end

    def ensure_success!(body, prefix)
      raise Error, "#{prefix}: #{body['errorMsg'] || body['msg']}" unless body["success"]
    end
end
