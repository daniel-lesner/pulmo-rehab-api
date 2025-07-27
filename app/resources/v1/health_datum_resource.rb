# frozen_string_literal: true

module V1
  class HealthDatumResource < ApplicationResource
    model_name "V1::HealthDatum"

    attributes :age, :gender, :weight, :height, :smoker,
               :primary_diagnosis, :copd_stage, :respiratory_failure,
               :angina, :hypertension, :venous_insufficiency,
               :spo2, :bp, :heart_rate,
               :fev1, :ipb, :fvc,
               :biseptol, :laba_lama, :ics, :acc, :ventolin

    has_one :user

    def create
      @model.user = context[:current_user]
      super
    end
  end
end
