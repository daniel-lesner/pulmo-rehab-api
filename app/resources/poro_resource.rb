# frozen_string_literal: true

# For version 0.10.X of the jsonapi-resources gem, support for models not backed up by table is currently broken
# In order to make it work, models should not inherit from ActiveRecord and the corresponding resources should use JSONAPI::BasicResources,
# as well as some overrides of its methods are needed
#
# https://github.com/cerebris/jsonapi-resources/issues/1306
# https://github.com/cerebris/jsonapi-resources-site/issues/45
# https://github.com/cerebris/jsonapi-resources/wiki/Using-JSONAPI::Resources-with-non-ActiveRecord-models-and-service-objects
#
# Some of the code is taken from https://github.com/cerebris/jsonapi-resources/blob/v0.10.7/test/fixtures/active_record.rb

class PoroResource < JSONAPI::BasicResource
  root_resource

  class << self
    def resource_klass
      self
    end

    def find_fragments(filters, options)
      fragments = {}
      find_records(filters, options).each do |record|
        rid = JSONAPI::ResourceIdentity.new(resource_klass, record.id)
        # We can use either the id or the full resource.
        # fragments[rid] = JSONAPI::ResourceFragment.new(rid)
        #  OR
        # fragments[rid] = JSONAPI::ResourceFragment.new(rid, resource: resource_klass.new(record, options[:context]))
        # In this case we will use the resource since we already looked up the model instance
        fragments[rid] = JSONAPI::ResourceFragment.new(rid)
      end
      fragments
    end

    def find_records(filters, options = {})
      [ options[:context][:created_model] ]
    end

    def find_to_populate_by_keys(keys, options = {})
      find_by_keys(keys, options)
    end

    def find_by_keys(keys, options = {})
      records = find_records_by_keys(keys, options)
      resources_for(records, options[:context])
    end

    def find_records_by_keys(keys, options = {})
      [ options[:context][:created_model] ]
    end

    def resource_klass_for(type)
      # type = type.split("::").last.gsub("Resource", "").downcase
      # type_with_module = type.start_with?(module_path) ? type : module_path + type

      # resource_name = _resource_name_from_type(type_with_module)
      # resource = resource_name.safe_constantize if resource_name

      # if resource.nil?
      #   fail NameError, "JSONAPI: Could not find resource '#{type}'. (Class #{resource_name} not found)"
      # end

      type.safe_constantize
    end
  end
end
