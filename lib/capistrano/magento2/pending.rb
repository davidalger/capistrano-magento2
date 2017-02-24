##
 # Copyright © 2016 by David Alger. All rights reserved
 # 
 # Licensed under the Open Software License 3.0 (OSL-3.0)
 # See included LICENSE file for full text of OSL-3.0
 # 
 # http://davidalger.com/contact/
 ##

require 'capistrano/deploy'

module Capistrano
  module Magento2
    module Pending
      def ensure_revision inform_user = false
        if test "[ -f #{current_path}/REVISION ]"
          yield
        elsif inform_user
          warn "\e[0;31mSkipping pending changes check on #{host} (no REVISION file found)\e[0m"
        end
      end

      def from_rev
        within current_path do
          current_revision = capture(:cat, "REVISION")

          run_locally do
            return capture(:git, "name-rev --always --name-only #{current_revision}") # find symbolic name for ref
          end
        end
      end

      def to_rev
        run_locally do
          to = fetch(:branch)

          # get target branch upstream if there is one
          if test(:git, "rev-parse --abbrev-ref --symbolic-full-name #{to}@{u}")
            to = capture(:git, "rev-parse --abbrev-ref --symbolic-full-name #{to}@{u}")
          end

          # find symbolic name for revision
          to = capture(:git, "name-rev --always --name-only #{to}")
        end
      end


      def log_pending(from, to)
        run_locally do
          output = capture :git, :log, "#{from}..#{to}", fetch(:magento_deploy_pending_format)

          if output.to_s.strip.empty?
            output = capture :git, :log, "#{to}..#{from}", fetch(:magento_deploy_pending_format)
            if not output.to_s.strip.empty?
              output += "\n\e[0;31mWarning: It appears you may be going backwards in time with this deployment!\e[0m"
            end
          end

          output.each_line do |line|
            info line
          end
        end
      end
    end
  end
end

load File.expand_path('../../tasks/pending.rake', __FILE__)
