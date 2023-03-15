class WikibaseExportVersion < ApplicationRecord
  class FileNotFound < StandardError
    attr_reader :path

    def initialize(path, msg = "Wikibase export file at '#{path}' not found.")
      super(msg)

      @path = path
    end
  end

  validates :file_hash, uniqueness: true

  class << self
    def version_exists?(path)
      exists? file_hash: file_signature(path)
    end

    def create_by_file!(path)
      create! file_hash: file_signature(path)
    end

    def file_signature path
      hash = IO.popen(['git', 'hash-object', path]) { |io| io.gets&.strip }
      raise FileNotFound.new(path) unless $?&.success?

      hash
    end
  end
end
