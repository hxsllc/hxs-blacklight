# frozen_string_literal: true

task stdout: :environment do
  Rails.logger = ActiveSupport::Logger.new($stdout)
end

task verbose: :environment do
  Rails.logger.level = Logger::DEBUG
end
