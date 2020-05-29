##
 # Copyright © 2016 by David Alger. All rights reserved
 # 
 # Licensed under the Open Software License 3.0 (OSL-3.0)
 # See included LICENSE file for full text of OSL-3.0
 # 
 # http://davidalger.com/contact/
 ##

require 'date'

SSHKit.config.command_map[:magento] = "/usr/bin/env php -f bin/magento --"

module Capistrano
  module Magento2
    module Helpers
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
