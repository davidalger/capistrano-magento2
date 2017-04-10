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
        return Gem::Version::new((capture :php, "-f #{release_path}/bin/magento -- -V --no-ansi").split(' ').pop)
      end

      def disabled_modules
        output = capture :magento, 'module:status --no-ansi'
        output = output.split("disabled modules:\n", 2)[1]

        if output == nil or output.strip == "None"
          return []
        end
        return output.split("\n")
      end

      def cache_hosts
        return fetch(:magento_deploy_cache_shared) ? (primary fetch :magento_deploy_setup_role) : (release_roles :all)
      end

      # Set pipefail allowing console exit codes in Magento 2.1.1 and later to halt execution when using pipes
      def Helpers.set_pipefail
        if not SSHKit.config.command_map[:magento].include? 'set -o pipefail' # avoids trouble on multi-host deploys
          @@pipefail_less = SSHKit.config.command_map[:magento].dup
          SSHKit.config.command_map[:magento] = "set -o pipefail; #{@@pipefail_less}"
        end
      end

      # Reset the command map without prefix, removing pipefail option so it won't affect other commands
      def Helpers.unset_pipefail
        SSHKit.config.command_map[:magento] = @@pipefail_less
      end
    end

    module Setup
      def static_content_deploy params
        Helpers.set_pipefail
        output = capture :magento,
          "setup:static-content:deploy --no-ansi #{params} | stdbuf -o0 tr -d .",
          verbosity: Logger::INFO
        Helpers.unset_pipefail

        # String based error checking is here to catch errors in Magento 2.1.0 and earlier; later versions will exit
        # immediately when a console exit code is retruned, never evaluating this code.
        if not output.to_s.include? 'New version of deployed files'
          raise Exception, "\e[0;31mFailed to compile static assets. No new version found in command output!\e[0m"
        end

        output.to_s.each_line { |line|
          if line.split('errors: ', 2).pop.to_i > 0
            raise Exception, "\e[0;31mFailed to compile static assets. Errors found in command output: #{line}\e[0m"
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
