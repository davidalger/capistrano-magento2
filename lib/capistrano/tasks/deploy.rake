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

  task :updated do
    on release_roles :all do
      within release_path do
        # If the auth.json file doesn't contain valid credentials, errors will be output to log/capistrano.log
        execute :composer, 'install --no-interaction 2>&1'
        
        # This may fail if the repository does not correctly contain the update dir
        if test "[ -d #{release_path}/update ]"
          execute :composer, 'install -d ./update 2>&1'
        end
        
        invoke 'magento:reset_permissions'
        invoke 'magento:cache:flush'
        invoke 'magento:setup:static_content:deploy'
        invoke 'magento:setup:di:compile_multi_tenant'
        invoke 'magento:reset_permissions'
        invoke 'magento:maintenance:enable'
        invoke 'magento:setup:upgrade'
        invoke 'magento:cache:varnish:ban'
        invoke 'magento:maintenance:disable'
      end
    end
  end

  task :reverted do
    on release_roles :all do
      within release_path do
        invoke 'magento:maintenance:disable'
        invoke 'magento:cache:flush'
        invoke 'magento:cache:varnish:ban'
      end
    end
  end

  # Check for pending changes and notify user of incoming changes or warn them that there are no changes
  before :starting, :check_for_changes do
    # Only check for pending changes if REVISION file exists
    on roles fetch(:capistrano_pending_role, :db) do |host|
      if test "[ -f #{current_path}/REVISION ]"
        invoke 'deploy:pending:log_changes'
      end
    end
  end

  before :starting, :confirm_action do
    if fetch(:stage).to_s == "prod"
      puts "\n\e[0;31m"
      puts "    ######################################################################"
      puts "    #                                                                    #"
      puts "    #        Are you sure you want to deploy to production? [y/N]        #"
      puts "    #                                                                    #"
      puts "    #             Use these commands to see pending changes:             #"
      puts "    #                     cap prod deploy:pending                        #"
      puts "    #                     cap prod deploy:pending:diff                   #"
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

  # Wrapper for the log_changes method
  namespace :pending do
    def _log_changes(from, to)
      _scm.log_changes(from, to)
    end

    task :log_changes => :setup do
      _log_changes(fetch(:revision), fetch(:branch))
    end
  end
end
