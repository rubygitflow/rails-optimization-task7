# frozen_string_literal: true
LOG_SEPARATOR = '; '
LOG_FILENAME = 'test_history.log'
namespace :test do
  desc 'run'
  task :run, [:init_config, :test_path, :limit_cpu_usage] => :environment do |_task, args|
    command = TTY::Command.new(pty: true, printer: :quiet, color: true)
    case args.init_config
    when 'default'
      cmd = 'rails db:environment:set RAILS_ENV=test'
      command.run(cmd)
    end
     
    if File.file?(args.test_path)
      cmd = "rspec --fail-fast=1 --format progress #{args.test_path}"
    else
      cmd = "rake parallel:#{args.test_path}"
      cmd += "[#{args.limit_cpu_usage}]" if !args.limit_cpu_usage.blank?
    end
    start = Time.now
    puts "#{I18n.l(start, format: :simple)}; Running #{cmd}"
    begin
      res = command.run(cmd)
      cmd_status ='TESTS COMPLETED SUCCESSFULLY'
    rescue TTY::Command::ExitError
      cmd_status = 'TEST FAILED SAFETY'
    end
    finish = Time.now
    result = I18n.l(finish, format: :simple)
      .concat(LOG_SEPARATOR, `echo $(logname)`.strip,
              LOG_SEPARATOR, cmd_status,
              LOG_SEPARATOR, "spent time (sec): #{(finish - start).to_i}",
              LOG_SEPARATOR, 'rspec ', args.test_path)
    logfile = File.open(Rails.root.join('tmp', LOG_FILENAME), 'a')
    logfile.puts result
    logfile.close 
    puts result
  end
end
