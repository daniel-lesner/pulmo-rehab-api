# frozen_string_literal: true

JSONAPI.configure do |config|
  # Built-in key format options are :underscored_key, :camelized_key, and :dasherized_key
  config.json_key_format = :camelized_key
  config.route_format = :camelized_route
  config.exception_class_whitelist << ActiveRecord::RecordInvalid
end
