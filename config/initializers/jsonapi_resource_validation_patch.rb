module JSONAPI
  class Resource
    alias_method :original_save, :save

    def save
      unless @model.valid?
        raise ActiveRecord::RecordInvalid.new(@model)
      end

      super
    end
  end
end
