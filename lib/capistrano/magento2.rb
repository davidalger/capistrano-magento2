##
 # Copyright © 2016 by David Alger. All rights reserved
 # 
 # Licensed under the Open Software License 3.0 (OSL-3.0)
 # See included LICENSE file for full text of OSL-3.0
 # 
 # http://davidalger.com/contact/
 ##

SSHKit.config.command_map[:magento] = "/usr/bin/env php -f bin/magento --"

module Capistrano
  module Magento2
    module Helpers
      def magento_version
        return Gem::Version::new((capture "/usr/bin/env php -f #{release_path}/bin/magento -- -V").split(' ').pop)
      end

      def disabled_modules
        output = capture :magento, 'module:status'
        output = output.split("disabled modules:\n", 2)[1]

        if output == nil or output.strip == "None"
          return []
        end
        return output.split("\n")
      end

      def cache_hosts
        return fetch(:magento_deploy_cache_shared) ? (primary fetch :magento_deploy_setup_role) : (release_roles :all)
      end
    end
    
    module Setup
      def static_content_deploy params
        # Setting pipefail causes the console exit codes introduced in Magento 2.1.1 to bubble up and halt execution
        # as is normally expected. Versions which do not return exit codes will fall back on the far less reliable
        # error checks we're doing on the command output
        SSHKit.config.command_map.prefix[:magento].push("set -o pipefail;")

        output = capture :magento,
          "setup:static-content:deploy #{params} | stdbuf -o0 tr -d .",
          verbosity: Logger::INFO

        # Clear the pipefail option from list of prefixes so it won't affect other commands
        SSHKit.config.command_map.prefix[:magento].pop

        # String based error checking is here to catch errors in Magento 2.1.0 and earlier
        if not output.to_s.include? 'New version of deployed files'
          raise Exception, "\e[0;31mFailed to compile static assets\e[0m"
        end

        output.to_s.each_line { |line|
          if line.split('errors: ', 2).pop.to_i > 0
            raise Exception, "\e[0;31mFailed to compile static assets\e[0m"
          end
        }
      end
    end
  end
end

load File.expand_path('../tasks/magento.rake', __FILE__)

namespace :load do
  task :defaults do
    load 'capistrano/magento2/defaults.rb'
  end
end
