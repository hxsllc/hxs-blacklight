# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever

# To execute: bundle exec whenever

# Email job output by setting the mailto: option
#   See https://github.com/javan/whenever#customize-email-recipient-with-the-mailto-environment-variable
every '0 0 * * *', mailto: 'test@example.com' do
  rake "data:migrate"
end
