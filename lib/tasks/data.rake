# frozen_string_literal: true

require_relative '../wikibase_ingest'
require_relative '../solr_data_migration'

namespace :data do
  # Ingest the wikibase data only
  #
  # @example
  #
  #   rake data:ingest
  #   rake "data:ingest[true]"
  #
  # @param [Boolean] force Still succeed when there are no changes
  desc 'Ingest the WikiBase data from the remote Git repository.'
  task :ingest, [:force] => %i[environment verbose stdout] do |_task, args|
    unless WikibaseIngest.new.execute! || args[:force]
      Rails.logger.warn 'No changes'
      exit 1
    end
  end

  # Convert the Wikibase export JSON file to Solr documents. Depends on the `lib/wiki-to-solr.rb` script file.
  #
  # @example
  #
  #   rake data:covert
  #   rake "data:covert[lib/import.json]"
  #   rake "data:covert[lib/import.json,lib/export.json]"
  #   rake "data:covert[lib/import.json,lib/export.json,true]"
  #
  # @param [String] output The path where to write the Solr Documents
  # @param [String] input The path to the wikibase export JSON file
  # @param [Boolean] verbose Verbose logging
  desc 'Convert the WikiBase exported JSON data file to the application Solr document.'
  task :convert, %i[output input verbose] => %i[environment verbose stdout] do |_task, args|
    args.with_defaults output: 'tmp/solr_data.json',
                       input: WikibaseIngest.json_file_full_path,
                       verbose: false

    commands = [
      'ruby',
      'wikibase-solr-raw.rb',
      '-i', File.expand_path(args[:input], Rails.root).to_s,
      '-o', File.expand_path(args[:output], Rails.root).to_s
    ]

    commands << '-v' if args[:verbose]
    FileUtils.rm_f args[:output]
    output = IO.popen(commands, err: :out, chdir: Rails.root.join('lib').to_s) { |io| io.readlines.compact }
    Rails.logger.info "[wikibase-solr-raw.rb] Converted Wiki data\n\t#{output}"
    exit 1 unless File.exist? args[:output]
  end

  # Seed the Solr server with the documents in the output file
  #
  # @example
  #
  #   rake data:seed
  #   rake "data:seed[tmp/solr_data.json]"
  #
  # @param [String] file The location of the Solr documents
  desc 'Seed the application Solr server with the JSON Solr document file.'
  task :seed, [:file] => %i[environment verbose stdout] do |_task, args|
    args.with_defaults file: 'tmp/solr_data.json'
    SolrDataMigration.new.migrate! args[:file]
  end

  # Ingest, Convert, and Seed the wikibase data to Solr
  #
  # @example
  #
  #   rake data:migrate
  #   rake "data:migrate[true]"
  #
  # @param [Boolean] force Force a migration even if there are no changes to the wiki export file
  desc 'Update the application Solr data based on the WikiBase export JSON file stored in the Git repository.'
  task :migrate, [:force] => %i[environment verbose stdout] do |_task, args|
    Rake::Task['data:ingest'].invoke args[:force]
    Rake::Task['data:convert'].invoke
    Rake::Task['data:seed'].invoke
  end
end
