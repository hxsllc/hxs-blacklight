
task stdout: :environment do
  Rails.logger = ActiveSupport::Logger.new(STDOUT)
end

task verbose: :environment do
  Rails.logger.level = Logger::DEBUG
end
