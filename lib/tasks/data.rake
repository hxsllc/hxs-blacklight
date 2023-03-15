require_relative '../wikibase_ingest'

namespace :data do
  # Ingest the wikibase data only
  task ingest: [:environment, :verbose, :stdout] do
    WikibaseIngest.new.execute!
  end

  # Ingest, Convert, and Upload the wikibase data to solr
  task :migrate do
    Rake::Task['data:ingest'].invoke # Ingest the wikibase data
  end
end