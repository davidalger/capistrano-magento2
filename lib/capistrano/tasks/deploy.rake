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
    on roles(:app) do
      within release_path do
        # If the auth.json file doesn't contain a Github OAuth and valid Magento credentials, errors will be output to log/capistrano.log
        execute :composer, 'install', '--no-interaction'
        # It is necessary to run install in the update directory in order to be able to run a CRON job
        execute :composer, 'install', '-d', './update'
        execute :chmod, '+x', './bin/magento'
      
        invoke 'magento:cache:flush'

        execute :php, '-f', 'bin/magento', '--', 'setup:upgrade'
        
        # Due to a bug (https://github.com/magento/magento2/issues/3060) in bin/magento, errors in the compilation will not
        # result in a non-zero exit code, so Capistrano is not aware an error has occurred. As a result, we must capture
        # the output and manually search for an error string to determine whether compilation is successful.
        # Once the aforementioned bug is fixed, pass a "-q" flag to 'setup:static-content:deploy' to silence verbose output, as right now 
        # the log is being filled with thousands of extraneous lines, per this issue: https://github.com/magento/magento2/issues/3692
        puts '    Compiling static content'
        set :static_content_deploy_output, capture(:php, '-f', 'bin/magento', '--', 'setup:static-content:deploy')
        if fetch(:static_content_deploy_output).to_s.include? 'Compilation from source'
          puts "\n\e[0;31m    ######################################################################\n" \
            "    #                                                                    #\n" \
            "    #                 Failed to compile static assets                    #\n" \
            "    #                                                                    #\n" \
            "    ######################################################################\n\n" \
            + fetch(:static_content_deploy_output) + \
            "\e[0m\n"
          raise Exception, 'Failed to compile static assets'
        else
          puts '    Static content compilation successful'
        end
        
        # TODO: Change this once the bug with single tenant compiler is fixed http://devdocs.magento.com/guides/v2.0/config-guide/cli/config-cli-subcommands-compiler.html#config-cli-subcommands-single
        execute :php, '-f', 'bin/magento', '--', 'setup:di:compile-multi-tenant', '-q'
      
        invoke 'magento:reset_permissions'
        invoke 'magento:varnish:ban'
      end
    end
  end

  task :reverted do
    on roles(:app) do
      within release_path do
        invoke 'magento:cache:flush'
        invoke 'magento:varnish:ban'
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
      puts "\n\e[0;31m    ######################################################################"
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
