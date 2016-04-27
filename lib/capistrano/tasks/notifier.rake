##
 # Copyright © 2016 by David Alger. All rights reserved
 # 
 # Licensed under the Open Software License 3.0 (OSL-3.0)
 # See included LICENSE file for full text of OSL-3.0
 # 
 # http://davidalger.com/contact/
 ##

require 'terminal-notifier'

namespace :deploy do
  before :starting, :confirm_action do
    if fetch(:deploy_warn_stages).include? fetch(:stage).to_s
      message = "Are you sure you want to deploy to #{fetch(:stage).to_s}? [y/N]".center(66)
      
      puts "\n\e[0;31m"
      puts "    ######################################################################"
      puts "    #                                                                    #"
      puts "    # #{message} #"
      puts "    #                                                                    #"
      puts "    ######################################################################\e[0m\n"
      proceed = STDIN.gets[0..0] rescue nil
      exit unless proceed == 'y' || proceed == 'Y'
    end
  end

  after 'deploy:failed', :notify_user_failure do
    run_locally do
      set :message, "ERROR in deploying " + fetch(:application).to_s + " to " + fetch(:stage).to_s
      TerminalNotifier.notify(fetch(:message), :title => 'Capistrano')
    end
  end

  after :finished, :notify_user do
    run_locally do
      set :message, "Finished deploying " + fetch(:application).to_s + " to " + fetch(:stage).to_s
      TerminalNotifier.notify(fetch(:message), :title => 'Capistrano')
    end
  end
end

namespace :load do
  task :defaults do
    set :deploy_warn_stages, fetch(:deploy_warn_stages, []).push('prod', 'production')
  end
end
