# frozen_string_literal: true

module V1
  class BraceletResource < ApplicationResource
    model_name "V1::Bracelet"

    attributes :name, :brand, :api_key

    has_one :user
  end
end
