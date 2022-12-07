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

    data = File.read Rails.root.join('config/solr-seed.json')
    solr = RSolr.connect url: ENV['SOLR_URL']
    solr.post "update", data: data, headers: { 'Content-Type' => 'application/json' }
    solr.commit
  end
end
