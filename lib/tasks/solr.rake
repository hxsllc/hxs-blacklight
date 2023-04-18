# frozen_string_literal: true

require_relative '../solr_schema_manager'

namespace :solr do
  namespace :schema do
    task update: :environment do
      manager = SolrSchemaManager.new
      manager.migrate!
    end
  end

  task seed: :environment do
    raise 'Can not seed production' if Rails.env.production?

    data = Rails.root.join('config/solr-seed.json').read
    solr = RSolr.connect url: ENV.fetch('SOLR_URL', nil)
    solr.post 'update', data: data, headers: { 'Content-Type' => 'application/json' }
    solr.commit
  end
end
