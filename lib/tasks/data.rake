require_relative '../wikibase_ingest'

namespace :data do
  # Ingest the wikibase data only
  task ingest: [:environment, :verbose, :stdout] do
    exit 1 unless WikibaseIngest.new.execute!
  end

  # Ingest, Convert, and Upload the wikibase data to solr
  task migrate: ['data:ingest'] do
  end
end