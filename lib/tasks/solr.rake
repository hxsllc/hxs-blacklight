# frozen_string_literal: true

require_relative '../solr_schema_manager'

namespace :solr do
  namespace :schema do
    desc 'Update the Solr server\'s schema based on the configuration file.'
    task update: :environment do
      manager = SolrSchemaManager.new
      manager.migrate!
    end
  end
end
