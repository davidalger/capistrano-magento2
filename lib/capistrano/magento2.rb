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
    end

    module Setup
      def static_content_deploy params
        if magento_version >= Gem::Version.new('2.2.0-rc')
          # Using -f here just in case MAGE_MODE environment variable in shell is set to something other than production
          execute :magento, "setup:static-content:deploy -f #{params}"
        else
          # Sets pipefail option in shell allowing command exit codes to halt execution when piping command output
          if not SSHKit.config.command_map[:magento].include? 'set -o pipefail' # avoids trouble on multi-host deploys
            @@pipefail_less = SSHKit.config.command_map[:magento].dup
            SSHKit.config.command_map[:magento] = "set -o pipefail; #{@@pipefail_less}"
          end

          execute :magento, "setup:static-content:deploy #{params} | stdbuf -o0 tr -d ."

          # Unsets pipefail option in shell so it won't affect future command executions
          SSHKit.config.command_map[:magento] = @@pipefail_less
        end
      end

      def deployed_version
        # Generate a static content version string, but only if one has not already been set on a previous call
        if not fetch(:magento_static_deployed_version)
          set :magento_static_deployed_version, DateTime.now.strftime("%s")
          info "Static content version: #{fetch(:magento_static_deployed_version)}"
        end
        return fetch(:magento_static_deployed_version)
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
