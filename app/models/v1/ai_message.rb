# frozen_string_literal: true

module V1
  class AiMessage < VirtualRecord
    attr_accessor :id, :prompt, :user_id, :reply, :suggestions, :context_id

    def initialize(attrs = {})
      @prompt      = attrs[:prompt]
      @user_id      = attrs[:user_id]
      @context_id  = attrs[:context_id]
      @reply       = attrs[:reply]
      @suggestions = attrs[:suggestions]
    end
  end
end
