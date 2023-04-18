# frozen_string_literal: true

# Solr Collection API Client
class SolrCollection
  class SolrCollectionError < StandardError; end
  class TimedOut < SolrCollectionError; end
  class RequestNotFound < SolrCollectionError; end
  class RequestInvalid < SolrCollectionError; end
  class BackupFailed < SolrCollectionError; end
  class RestoreFailed < SolrCollectionError; end

  attr_reader :uri, :collection

  # @option [String] uri The URI to the solr server; parsed from the `SOLR_ENV` environment variable
  # @option [String] collection The collection name; parsed from the `SOLR_ENV` environment variable
  def initialize(uri: nil, collection: nil)
    @uri = uri
    @collection = collection
    @uri, @collection = uri_from_env if @uri.blank?

    @connection = Faraday.new(@uri) do |f|
      f.request :json
      f.response :json
    end
  end

  # Create a backup of the collection
  # @param [String] id The name of the backup
  # @option [Numeric] timeout The number of seconds to wait for the backup to be created
  # @option [Numeric] interval The number of seconds to wait before checking on the backup status
  # @option [string] location The shared network location to store the backup
  # @raise [SolrCollection::RequestNotFound] if the solr server returns a 404
  # @raise [SolrCollection::RequestInvalid] if the solr server has an error
  # @raise [SolrCollection::TimedOut] if unable to get a completed status
  # @return [JSON] the JSON response body
  def create_backup(id, timeout: nil, interval: nil, location: nil)
    Rails.logger.info "[SolrCollection] Creating Backup #{id}"
    params = { action: 'BACKUP', name: id, collection: @collection, location: location || default_backup_location }
    response = execute_and_wait params, timeout, interval
    if response['status']['state'] == 'failed'
      raise BackupFailed,
            "Unable to create the backup: #{response['status']['msg']}"
    end

    response
  end

  # Restore from a backup of the collection
  # @param [String] id The name of the backup
  # @option [Numeric] timeout The number of seconds to wait for the restore to complete
  # @option [Numeric] interval The number of seconds to wait before checking on the restore status
  # @option [string] location The shared network location to store the backup
  # @raise [SolrCollection::RequestNotFound] if the solr server returns a 404
  # @raise [SolrCollection::RequestInvalid] if the solr server has an error
  # @raise [SolrCollection::TimedOut] if unable to get a completed status
  # @return [JSON] the JSON response body
  def restore_backup(id, timeout: nil, interval: nil, location: nil)
    Rails.logger.info "[SolrCollection] Restoring Backup #{id}"
    params = { action: 'RESTORE', name: id, collection: @collection, location: location || default_backup_location }
    response = execute_and_wait params, timeout, interval
    if response['status']['state'] == 'failed'
      raise RestoreFailed,
            "Unable to restore the backup: #{response['status']['msg']}"
    end

    response
  end

  # Get the request status of an async task
  # @param [String, Numeric] request_id The ID of the async task
  # @raise [SolrCollection::RequestNotFound] if the solr server returns a 404
  # @raise [SolrCollection::RequestInvalid] if the solr server has an error
  # @return [JSON] the JSON response body
  def request_status(request_id)
    Rails.logger.info "[SolrCollection] Getting request status #{request_id}"
    response = @connection.get nil, action: 'REQUESTSTATUS', requestid: request_id
    raise RequestInvalid if response.status != 200

    status = response.body['status']&.dig('state')
    raise RequestNotFound if status == 'notfound'

    response.body if %w[completed failed].include? status # Might be better to use the wait status here
  end

  private

  def default_backup_location
    ENV['SOLR_BACKUP_LOCATION'] || '/var/solr/data'
  end

  def execute(params)
    response = @connection.get nil, params
    raise RequestInvalid, response.body['error']&.dig('msg') || 'Invalid Request' if response.status != 200
    raise RequestInvalid, response.body['error'] if response.body['error'].present?

    response
  end

  def execute_and_wait(params, timeout, interval)
    request_id = "request#{Time.now.utc.to_i}"
    execute params.merge(async: request_id)
    wait request_id, timeout, interval
  end

  def wait(request_id, timeout, interval)
    timeout ||= ENV.fetch('SOLR_BACKUP_TIMEOUT', 5.minutes.to_i).to_f
    interval ||= ENV.fetch('SOLR_BACKUP_WAIT_INTERVAL', 1.second.to_i).to_f

    start_time = Time.now.utc
    response = request_status request_id

    until response.present? || start_time - Time.now.utc >= timeout
      Rails.logger.debug do
        "Waiting #{interval} seconds of #{timeout} seconds - #{timeout - (start_time - Time.now.utc)} seconds remaining"
      end
      sleep interval
      response = request_status request_id
    end

    raise TimedOut, "Unable to get the response results for #{request_id}" if response.blank?

    response
  end

  def uri_from_env
    return [nil, nil] if ENV['SOLR_URL'].blank?

    template = Addressable::Template.new '/solr/{core}'
    uri = Addressable::URI.parse ENV.fetch('SOLR_URL', nil)
    collection_uri = uri.join('/solr/admin/collections')
    extracted = template.extract uri.path
    collection_name = extracted.present? ? extracted['core'] : nil
    [collection_uri.to_s, collection_name || @collection]
  end
end
