# frozen_string_literal: true

module V1
  class Dashboard < VirtualRecord
    attr_accessor :id, :bracelet_id, :bracelet_type, :date, :data_type, :data
  end
end
