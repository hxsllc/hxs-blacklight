# frozen_string_literal: true

# Compares the local schema configuration with the Solr server configuration
#  making the necessary changes (add, remove, updates) to the Solr server.
class SolrSchemaManager
  # Base Solr Schema Manager error
  class SolrError < StandardError; end

  # Describes the duplicate field in the local solr schema configuration
  class DuplicateFieldSolrError < SolrError
    attr_reader :type, :name, :definition

    def initialize(type, name, msg = nil, definition = nil)
      @type = type
      @name = name
      @definition = definition

      super msg || "Duplicate #{name} #{type} records found."
    end
  end

  def config
    @config ||= normalize_schema YAML.load_file(Rails.root.join('config/solr-schema.yml'))
  end

  def server_config
    @server_config ||= begin
                         response = solr.get "schema"

                         if response["responseHeader"]["status"] != 0
                           raise SolrError.new("Unable to retrieve schema (status: #{response["responseHeader"]["status"]})")
                         end

                         normalize_schema response["schema"]
                       end
  end

  def config_diffs
    diffs = Hashdiff.diff server_config, config, indifferent: true, array_path: true

    diffs.inject({}) do |hash, diff|
      action, path = diff
      type, name, attr = path
      hash[type] ||= {}
      hash[type][name] ||= attr ? :replace : diff_action(action)
      hash
    end
  end

  def migrate!
    commands = config_diffs.inject({}) do |hash, (type, diffs)|
      diffs.each do |name, action|
        if type == 'copyFields'
          hash['remove-copy-field'] ||= []
          hash['remove-copy-field'] << server_config[type][name]
          hash['add-copy-field'] ||= []
          hash['add-copy-field'] << config[type][name]
        else
          command = "#{action}-#{type.underscore.singularize.gsub('_', '-')}"
          hash[command] ||= []
          hash[command] << (action == :delete ? { "name" => name } : config[type][name])
        end
      end
      hash
    end

    return if commands.empty?

    response = solr.update path: "schema",
                           data: JSON.generate(commands),
                           headers: { 'Content-Type' => 'application/json' }

    raise SolrError.new('Unable to update schema') unless response["responseHeader"]["status"] == 0
  end

  private

  def solr
    @solr ||= RSolr.connect url: ENV['SOLR_URL']
  end

  def normalize_schema(schema)
    {
      "fields" => normalize_fields("fields", schema["fields"]),
      "dynamicFields" => normalize_fields("dynamicFields", schema["dynamicFields"]),
      "copyFields" => normalize_copy_fields(schema["copyFields"]),
      "fieldTypes" => normalize_fields("fieldTypes", schema["fieldTypes"])
    }
  end

  def normalize_fields(field_type, fields)
    fields.inject({}) do |hash, field|
      unless field["name"].start_with?("_") && field["name"].end_with?("_")
        raise DuplicateFieldSolrError.new(field_type, field["name"], nil, field) if hash.key? field["name"]

        hash[field["name"]] = field
      end
      hash
    end
  end

  def normalize_copy_fields(copy_fields)
    copy_fields.inject({}) do |hash, copy_field|
      hash["#{copy_field["source"]}_#{Array(copy_field["dest"]).join('_')}"] = copy_field
      hash
    end
  end

  def diff_action(char)
    case char
    when "-"
      :delete
    when "+"
      :add
    else
      :replace
    end
  end
end
