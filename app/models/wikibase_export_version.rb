# Wikibase Export Version represents a snapshot of the Wikibase JSON export to keep track of changes.
class WikibaseExportVersion < ApplicationRecord
  # File Not Found Error
  class FileNotFound < StandardError
    attr_reader :path

    # @param path [String] the full path to the file
    # @param msg [String] the error message
    def initialize(path, msg = "Wikibase export file at '#{path}' not found.")
      super(msg)

      @path = path
    end
  end

  validates :file_hash, uniqueness: true

  class << self
    # Check to see if the file version exists in the database
    #
    # @param path [String] the full path to the file.
    #
    # @return [Boolean] true if the file version already exists in the database
    def version_exists?(path)
      exists? file_hash: file_signature(path)
    end

    # Create a new WikibaseExportVersion row based on the file
    #
    # @param path [String] the full path to the file.
    #
    # @return [WikibaseExportVersion] the persisted row in the database
    #
    # @raise [ActiveRecord::RecordNotSaved] if the new row could not be created
    def create_by_file!(path)
      create! file_hash: file_signature(path)
    end

    # Get the SHA1 value for the file stored in GIT
    #
    # @param path [String] the full path to the file
    #
    # @return [String] the SHA1 hash string stored in GIT
    #
    # @raise [FileNotFound] if the file could not be found
    def file_signature(path)
      raise FileNotFound.new(path) unless File.exist? path

      IO.popen(['git', 'hash-object', path]) { |io| io.gets&.strip }
    end
  end
end
