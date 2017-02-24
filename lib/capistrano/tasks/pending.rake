##
 # Copyright © 2016 by David Alger. All rights reserved
 # 
 # Licensed under the Open Software License 3.0 (OSL-3.0)
 # See included LICENSE file for full text of OSL-3.0
 # 
 # http://davidalger.com/contact/
 ##

include Capistrano::Magento2::Pending

before :deploy, 'deploy:pending:warn'

namespace :deploy do
  desc "Displays a summary of commits pending deployment"
  task :pending => 'deploy:pending:log'

  namespace :pending do
    task :warn => :log do
      if fetch(:magento_deploy_pending_warn)
        need_warning = true

        on roles fetch(:magento_deploy_pending_role) do |host|
          ensure_revision do
            if from_rev != to_rev
              need_warning = false
            end
          end
        end

        # if there is nothing to deploy on any node, prompt user for confirmation
        if need_warning
          print "      Are you sure you want to continue? [y/n] \e[0m"

          proceed = STDIN.gets[0..0] rescue nil
          exit unless proceed == 'y' || proceed == 'Y'
        end
      end
    end

    task :log do
      on roles fetch(:magento_deploy_pending_role) do |host|
        ensure_revision true do
          # update local repository to ensure accuracy of report
          run_locally do
            execute :git, :fetch, :origin
          end

          # fetch current revision and revision to be deployed
          from = from_rev
          to = to_rev

          # output prettified log of changes between from and to commits
          if from == to
            info "\e[0;31mNo changes to deploy on #{host} (from and to are the same: #{from} -> #{to})\e[0m"
          else
            info "\e[0;90mChanges pending deployment on #{host} (#{from} -> #{to}):\e[0m"
            log_pending(from, to)
          end
        end
      end
    end
  end
end
