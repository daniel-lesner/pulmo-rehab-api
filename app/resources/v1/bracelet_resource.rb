# frozen_string_literal: true

module V1
  class BraceletResource < ApplicationResource
    model_name "V1::Bracelet"

    attributes :name, :brand, :api_key

    has_one :user

    before_create :set_user

    private

      def set_user
        self.user_id = context[:current_user].id
      end
  end
end
