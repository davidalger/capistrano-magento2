##
 # Copyright © 2016 by David Alger. All rights reserved
 # 
 # Licensed under the Open Software License 3.0 (OSL-3.0)
 # See included LICENSE file for full text of OSL-3.0
 # 
 # http://davidalger.com/contact/
 ##

include Capistrano::Magento2::Helpers

namespace :deploy do
  before 'deploy:check:linked_files', 'magento:deploy:check'
  before 'deploy:symlink:linked_files', 'magento:deploy:local_config'

  # If both 'scopes' and 'themes' are available in app/etc/config.php then the build should not require database or
  # cache backend configuration to deploy. Removing the link to app/etc/env.php in this case prevents any possible
  # side effects that may arise from the build running in parallel to the live production release (such as the cache
  # being randomly disabled during the composer install step of the build, something which has been observed). This
  # requires "bin/magento scopes themes i18n" be run to dump theme/store config and the result comitted to repository
  before 'deploy:symlink:linked_files', :detect_scd_config do
    on primary fetch(:magento_deploy_setup_role) do
      unless test %Q[#{SSHKit.config.command_map[:php]} -r '
            $cfg = include "#{release_path}/app/etc/config.php";
            exit((int)(isset($cfg["scopes"]) && isset($cfg["themes"])));
        ']
        info "Removing app/etc/env.php from :linked_dirs for zero-side-effect pipeline deployment."
        remove :linked_files, 'app/etc/env.php'
      end
    end
  end

  before :starting, :confirm_action do
    if fetch(:magento_deploy_confirm).include? fetch(:stage).to_s
      print "\e[0;31m      Are you sure you want to deploy to #{fetch(:stage).to_s}? [y/n] \e[0m"
      proceed = STDIN.gets[0..0] rescue nil
      exit unless proceed == 'y' || proceed == 'Y'
    end
  end

  # Links app/etc/env.php if previously dropped from :linked_dirs in :detect_scd_config
  task 'symlink:link_env_php' do
    on release_roles :all do
      # Normally this would be wrapped in a conditional, but during SCD and/or DI compile Magento frequently writes
      # to cache_types -> compiled_config resulting in an env.php file being present (albeit the wrong one)
      execute :ln, "-fsn #{shared_path}/app/etc/env.php #{release_path}/app/etc/env.php"
    end
  end

  task :updated do
    invoke 'magento:deploy:verify'
    invoke 'magento:composer:install' if fetch(:magento_deploy_composer)
    invoke 'magento:deploy:version_check'
    invoke 'magento:setup:permissions'

    if fetch(:magento_deploy_production)
      invoke 'magento:setup:static-content:deploy'
      invoke 'magento:setup:di:compile'
      invoke 'magento:composer:dump-autoload' if fetch(:magento_deploy_composer)
    end

    invoke 'deploy:symlink:link_env_php'

    if fetch(:magento_deploy_production)
      invoke 'magento:deploy:mode:production'
    end

    invoke 'magento:setup:permissions'
    invoke 'magento:maintenance:check'
    invoke 'magento:maintenance:enable' if fetch(:magento_deploy_maintenance)

    on release_roles :all do
      if test "[ -f #{current_path}/bin/magento ]"
        within current_path do
          execute :magento, 'maintenance:enable' if fetch(:magento_deploy_maintenance)
        end
      end
    end

    # The app:config:import command was introduced in 2.2.0; check if it exists before invoking it
    on primary fetch(:magento_deploy_setup_role) do
      within release_path do
        if test :magento, 'app:config:import --help >/dev/null 2>&1'
          if not fetch(:magento_internal_zero_down_flag)
            invoke 'magento:app:config:import'
          end
        end
      end
    end

    invoke 'magento:setup:db:schema:upgrade' if not fetch(:magento_internal_zero_down_flag)
    invoke 'magento:setup:db:data:upgrade' if not fetch(:magento_internal_zero_down_flag)

    on primary fetch(:magento_deploy_setup_role) do
      within release_path do
        _disabled_modules = disabled_modules
        if _disabled_modules.count > 0
          info "\nThe following modules are disabled per app/etc/config.php:\n"
          _disabled_modules.each do |module_name|
            info '- ' + module_name
          end
        end
      end
    end
  end

  task :published do
    invoke 'magento:cache:flush'
    invoke 'magento:cache:varnish:ban'
    invoke 'magento:maintenance:disable' if fetch(:magento_deploy_maintenance)
  end
end
