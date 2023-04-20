# frozen_string_literal: true

desc 'INTERNAL ONLY! - Setup the Rails logger to use STDOUT'
task stdout: :environment do
  Rails.logger = ActiveSupport::Logger.new($stdout)
end

desc 'INTERNAL ONLY! - Setup the Rails logger log level to Debug'
task verbose: :environment do
  Rails.logger.level = Logger::DEBUG
end
