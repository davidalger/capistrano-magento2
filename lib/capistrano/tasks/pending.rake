##
 # Copyright © 2016 by David Alger. All rights reserved
 # 
 # Licensed under the Open Software License 3.0 (OSL-3.0)
 # See included LICENSE file for full text of OSL-3.0
 # 
 # http://davidalger.com/contact/
 ##

include Capistrano::Magento2::Pending

before 'deploy:check', 'deploy:pending:warn'

namespace :deploy do
  desc "Displays a summary of commits pending deployment"
  task :pending => 'deploy:pending:log'

  namespace :pending do
    task :warn => :log do
      if fetch(:magento_deploy_pending_warn)
        need_warning = true

        on roles fetch(:magento_deploy_pending_role) do |host|
          has_revision = ensure_revision do
            # if any host has a change in revision, do not warn user
            need_warning = false if from_rev != to_rev
          end

          # if a host does not have a revision, do not warn user
          need_warning = false if not has_revision
        end

        # if there is nothing to deploy on any host, prompt user for confirmation
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

          # if there is nothing to deploy on this host, inform the user
          if from == to
            info "\e[0;31mNo changes to deploy on #{host} (from and to are the same: #{from} -> #{to})\e[0m"
          else
            run_locally do
              header = "\e[0;90mChanges pending deployment on #{host} (#{from} -> #{to}):\e[0m\n"

              # capture log of commits between current revision and revision for deploy
              output = capture :git, :log, "#{from}..#{to}", fetch(:magento_deploy_pending_format)

              # if we get no results, flip refs to look at reverse log in case of rollback deployments
              if output.to_s.strip.empty?
                output = capture :git, :log, "#{to}..#{from}", fetch(:magento_deploy_pending_format)
                if not output.to_s.strip.empty?
                  header += "\e[0;31mWarning: It appears you may be going backwards in time on #{host} with this deployment!\e[0m\n"
                end
              end

              # write pending changes log
              (header + output).each_line do |line|
                info line
              end
            end
          end
        end
      end
    end
  end
end
