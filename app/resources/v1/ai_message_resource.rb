# frozen_string_literal: true

module V1
  class AiMessageResource < PoroResource
    model_name "V1::AiMessage"
    attributes :prompt, :user_id, :context_id, :reply, :suggestions

    def save
      prompt     = @model.prompt.to_s
      context_id = @model.context_id

      svc = ::AiService.new(
        prompt: prompt,
        context_id: context_id,
        user_id: user_id
      )

      @model.reply       = svc.reply
      @model.suggestions = svc.suggestions
      @model.context_id  = svc.context_id
      @model.id          ||= SecureRandom.uuid

      context[:created_model] = @model
    end
  end
end
