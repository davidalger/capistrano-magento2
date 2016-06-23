##
 # Copyright © 2016 by David Alger. All rights reserved
 # 
 # Licensed under the Open Software License 3.0 (OSL-3.0)
 # See included LICENSE file for full text of OSL-3.0
 # 
 # http://davidalger.com/contact/
 ##

namespace :deploy do
  before :starting, 'deploy:pending:check_changes'
  
  namespace :pending do
    # Wrapper for the log method that sets the return type to return the output rather than output it
    def _log_return(from, to)
      _scm.log(from, to, true)
    end
    
    # Check for pending changes and notify user of incoming changes or warn them that there are no changes
    task :check_changes => :setup do
      on roles fetch(:capistrano_pending_role, :app) do |host|
        # Only check for pending changes if REVISION file exists to prevent error
        if test "[ -f #{current_path}/REVISION ]"
          from = fetch(:revision)
          to = fetch(:branch)
          output = _log_return(from, to)
          # TODO: Centralize the notification code between this and deploy:confirm_action
          if output.to_s.strip.empty?
            puts "\e[0;31mNo changes to deploy (from and to are the same: #{from}..#{to}). \nAre you sure you want to continue deploying? [y/N]\e[0m"
            proceed = STDIN.gets[0..0] rescue nil
            exit unless proceed == 'y' || proceed == 'Y'
          else
            puts "Deploying changes between #{from}..#{to}"
            puts output
          end
        end
      end
    end
  end
  
end
