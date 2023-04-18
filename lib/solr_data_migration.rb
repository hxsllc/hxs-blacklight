# frozen_string_literal: true

require_relative 'solr_collection'

# Solr data migrations
class SolrDataMigration
  attr_reader :solr_collection, :solr

  # @option [Boolean] backup_solr Backup the solr server before seeding the data
  # @option [String] solr_collection The name of the solr collection; parsed from the `SOLR_URL` environment variable
  # @option [String] solr_uri The root uri to the solr server (example: 'http://localhost:8983/solr');
  #   parsed from the `SOLR_URl` environment variable
  def initialize(backup_solr: true, solr_collection: nil, solr_uri: nil)
    @backup_solr = backup_solr
    @solr_collection = solr_collection || SolrCollection.new
    @solr = RSolr.connect url: solr_uri || ENV.fetch('SOLR_URL', nil)
  end

  # Backup enabled
  # @return [Boolean]
  def backup_solr?
    !!@backup_solr
  end

  # Migrate the solr data
  # @param [String] file The file path to the Solr document JSON file
  # @option [Numeric] timeout The number of seconds before failing when creating the backup or restoring
  # @option [Numeric] interval How long to wait before trying again when creating the backup or restoring
  # @option [String] backup_location The shared network drive to store the backup on
  def migrate!(file, timeout: nil, interval: nil, backup_location: nil)
    file = File.expand_path(file, Rails.root).to_s
    Rails.logger.info "[SolrDataMigration] Migrating solr data (file: #{file})"
    documents = JSON.load_file file
    backup_id = "backup#{Time.now.utc.to_i}"
    if backup_solr?
      solr_collection.create_backup backup_id, timeout: timeout, interval: interval,
                                               location: backup_location
    end

    begin
      delete_all_documents!
      add_documents! documents
    rescue StandardError
      if backup_solr?
        solr_collection.restore_backup backup_id, timeout: timeout, interval: interval,
                                                  location: backup_location
      end
      raise
    end
  end

  private

  def delete_all_documents!
    Rails.logger.debug '[SolrDataMigration] Deleting all records'
    solr.delete_by_query '*:*'
    solr.commit
  end

  def add_documents!(documents)
    Rails.logger.debug '[SolrDataMigration] Adding new documents'
    solr.add documents
    solr.commit
  end
end
