# frozen_string_literal: true

class AiService
  class ProviderError < StandardError; end

  attr_reader :reply, :user_id, :suggestions, :context_id

  def initialize(prompt:, context_id: nil, user_id: nil)
    @prompt     = prompt.to_s
    @context_id = context_id
    @user_id       = user_id

    raise ProviderError, "prompt can't be blank" if @prompt.blank?

    run!
  end

  private

    def run!
      api_key = ENV["GROQ_API_KEY"]
      raise ProviderError, "GROQ_API_KEY missing" if api_key.blank?

      body = {
        model: ENV.fetch("GROQ_MODEL", "llama-3.3-70b-versatile"),
        temperature: 0.2,
        max_tokens: 800,
        messages: build_messages
      }

      base = ENV.fetch("GROQ_API_BASE", "https://api.groq.com")
      uri  = URI.join(base, "/openai/v1/chat/completions")

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == "https")

      req = Net::HTTP::Post.new(uri)
      req["Authorization"] = "Bearer #{api_key}"
      req["Content-Type"]  = "application/json"
      req.body = JSON.generate(body)

      res = http.request(req)
      raise ProviderError, "Groq HTTP #{res.code} - #{res.body}" unless res.is_a?(Net::HTTPSuccess)

      data = JSON.parse(res.body)
      text = data.dig("choices", 0, "message", "content").to_s.strip
      cid  = data["id"]

      @reply       = text
      @suggestions = extract_exercises(text)
      @context_id  = cid.presence || @context_id
    rescue => e
      Rails.logger.error("[AiService] #{e.class}: #{e.message}")
      raise
    end

    def build_messages
      user = V1::User.find_by(id: @user_id)
      profile = user_profile_snippet(user)

      system_content = <<~SYS
      You are a physiotherapy assistant. Ask concise clarifying questions only if truly needed.
      Return actionable exercise recommendations adapted to pain description and basic profile.
      Prefer bodyweight / low-risk movements. Structure response in short paragraphs and bullet points.
    SYS

      user_content = <<~USR
      Patient profile:
      #{profile}

      Pain description: #{@prompt}

      Please provide:
      - Brief reasoning (1–2 sentences)
      - 3–6 recommended exercises with sets/reps/timing
      - Safety notes and when to stop
      - Optional: progression/regression
    USR

      msgs = [
        { role: "system", content: system_content },
        { role: "user",   content: user_content }
      ]

      msgs.unshift({ role: "system", content: "Conversation ID: #{@context_id}" }) if @context_id.present?
      msgs
    end

    def user_profile_snippet(user)
      return "Unknown age/sex/conditions." unless user

      hd = user.try(:health_datum) || user.try(:healthDatum)

      parts = []
      parts << "Sex: #{hd.gender}" if hd&.gender.present?
      parts << "Age: #{hd.age}" if hd&.age.present?
      parts << "Weight: #{hd.weight} kg" if hd&.weight.present?
      parts << "Height: #{hd.height} cm" if hd&.height.present?
      parts << "Smoker: #{hd.smoker ? 'yes' : 'no'}" if hd.respond_to?(:smoker)

      conditions = []
      %i[
          primary_diagnosis copd_stage respiratory_failure
          angina hypertension venous_insufficiency
      ].each do |attr|
        val = hd&.public_send(attr)
        conditions << "#{attr.to_s.humanize}: #{val}" if val.present?
      end
      parts << "Known conditions: #{conditions.join(', ')}" if conditions.any?

      %i[spo2 bp heart_rate fev1 ipb fvc].each do |metric|
        val = hd&.public_send(metric)
        parts << "#{metric.to_s.upcase}: #{val}" if val.present?
      end

      parts.presence || "Unknown age/sex/conditions."
    end

    def extract_exercises(text)
      text.split("\n")
          .map(&:strip)
          .grep(/\A(\-|\*|\d+\.)\s+/)
          .map { |l| l.sub(/\A(\-|\*|\d+\.)\s+/, "") }
          .first(10)
    end
end
