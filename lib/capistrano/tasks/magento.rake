##
 # Copyright © 2016 by David Alger. All rights reserved
 #
 # Licensed under the Open Software License 3.0 (OSL-3.0)
 # See included LICENSE file for full text of OSL-3.0
 #
 # http://davidalger.com/contact/
 ##

include Capistrano::Magento2::Helpers
include Capistrano::Magento2::Setup

namespace :magento do

  namespace :cache do
    desc 'Flush Magento cache storage'
    task :flush do
      on cache_hosts do
        within release_path do
          execute :magento, 'cache:flush'
        end
      end
    end

    desc 'Clean Magento cache by types'
    task :clean do
      on cache_hosts do
        within release_path do
          execute :magento, 'cache:clean'
        end
      end
    end

    desc 'Enable Magento cache'
    task :enable do
      on cache_hosts do
        within release_path do
          execute :magento, 'cache:enable'
        end
      end
    end

    desc 'Disable Magento cache'
    task :disable do
      on cache_hosts do
        within release_path do
          execute :magento, 'cache:disable'
        end
      end
    end

    desc 'Check Magento cache enabled status'
    task :status do
      on cache_hosts do
        within release_path do
          execute :magento, 'cache:status'
        end
      end
    end

    namespace :varnish do
      # TODO: Document what the magento:cache:varnish:ban task is for and how to use it. See also magento/magento2#4106
      desc 'Add ban to Varnish for url(s)'
      task :ban do
        on primary fetch(:magento_deploy_setup_role) do
          # TODO: Document use of :ban_pools and :varnish_cache_hosts in project config file
          next unless any? :ban_pools
          next unless any? :varnish_cache_hosts

          within release_path do
            for pool in fetch(:ban_pools) do
              for cache_host in fetch(:varnish_cache_hosts) do
                execute :curl, %W{-s -H 'X-Pool: #{pool}' -X PURGE #{cache_host}}
              end
            end
          end
        end
      end
    end
  end

  namespace :composer do
    desc 'Run composer install'
    task :install do

      on release_roles :all do
        within release_path do
          composer_flags = '--prefer-dist --no-interaction'

          if fetch(:magento_deploy_production)
            composer_flags += ' --optimize-autoloader'
          end

          execute :composer, "install #{composer_flags} 2>&1"

          if fetch(:magento_deploy_production) and magento_version >= Gem::Version.new('2.1')
            composer_flags += ' --no-dev'
            execute :composer, "install #{composer_flags} 2>&1" # removes require-dev components from prev command
          end

          if test "[ -d #{release_path}/update]"   # can't count on this, but emit warning if not present

            if test "[ -f #{release_path}/update/composer.json]"
              execute :composer, "install #{composer_flags} -d ./update 2>&1"
            else
              info "\e[0;31m    Warning: ./update/composer.json file does not exist in the repository\n\e[0m\n"
            end
          else
            info "\e[0;31m    Warning: ./update dir does not exist in repository!\n\e[0m\n"
          end
        end
      end
    end
  end

  namespace :deploy do
    task :check do
      on release_roles :all do
        next unless any? :linked_files_touch
        on release_roles :all do |host|
          join_paths(shared_path, fetch(:linked_files_touch)).each do |file|
            unless test "[ -f #{file} ]"
              execute "touch #{file}"
            end
          end
        end
      end
    end

    task :verify do
      is_err = false
      on release_roles :all do
        unless test "[ -f #{release_path}/app/etc/config.php ]"
          error "\e[0;31mThe repository is missing app/etc/config.php. Please install the application and retry!\e[0m"
          exit 1  # only need to check the repo once, so we immediately exit
        end

        unless test %Q[#{SSHKit.config.command_map[:php]} -r '
              $cfg = include "#{release_path}/app/etc/env.php";
              exit((int)!isset($cfg["install"]["date"]));
          ']
          error "\e[0;31mError on #{host}:\e[0m No environment configuration could be found." +
                " Please configure app/etc/env.php and retry!"
          is_err = true
        end
      end
      exit 1 if is_err
    end
  end

  namespace :setup do
    desc 'Updates the module load sequence and upgrades database schemas and data fixtures'
    task :upgrade do
      on primary fetch(:magento_deploy_setup_role) do
        within release_path do
          warn "\e[0;31mWarning: Use of magento:setup:upgrade on production systems is discouraged." +
               " See https://github.com/davidalger/capistrano-magento2/issues/34 for details.\e[0m\n"

          execute :magento, 'setup:upgrade --keep-generated'
        end
      end
    end

    namespace :db do
      desc 'Checks if database schema and/or data require upgrading'
      task :status do
        on primary fetch(:magento_deploy_setup_role) do
          within release_path do
            execute :magento, 'setup:db:status'
          end
        end
      end

      task :upgrade do
        on primary fetch(:magento_deploy_setup_role) do
          within release_path do
            db_status = capture :magento, 'setup:db:status', verbosity: Logger::INFO

            if not db_status.to_s.include? 'All modules are up to date'
              execute :magento, 'setup:db-schema:upgrade'
              execute :magento, 'setup:db-data:upgrade'
            end
          end
        end
      end

      desc 'Upgrades data fixtures'
      task 'schema:upgrade' do
        on primary fetch(:magento_deploy_setup_role) do
          within release_path do
            execute :magento, 'setup:db-schema:upgrade'
          end
        end
      end

      desc 'Upgrades database schema'
      task 'data:upgrade' do
        on primary fetch(:magento_deploy_setup_role) do
          within release_path do
            execute :magento, 'setup:db-data:upgrade'
          end
        end
      end
    end

    desc 'Sets proper permissions on application'
    task :permissions do
      on release_roles :all do
        within release_path do
          execute :find, release_path, "-type d -exec chmod #{fetch(:magento_deploy_chmod_d).to_i} {} +"
          execute :find, release_path, "-type f -exec chmod #{fetch(:magento_deploy_chmod_f).to_i} {} +"

          fetch(:magento_deploy_chmod_x).each() do |file|
            execute :chmod, "+x #{release_path}/#{file}"
          end
        end
      end
      Rake::Task['magento:setup:permissions'].reenable  ## make task perpetually callable
    end

    namespace :di do
      desc 'Runs dependency injection compilation routine'
      task :compile do
        on release_roles :all do
          within release_path do
            # Due to a bug in the single-tenant compiler released in 2.0 (see here for details: http://bit.ly/21eMPtt)
            # we have to use multi-tenant currently. However, the multi-tenant is being dropped in 2.1 and is no longer
            # present in the develop mainline, so we are testing for multi-tenant presence for long-term portability.
            if test :magento, 'setup:di:compile-multi-tenant --help >/dev/null 2>&1'
              output = capture :magento, 'setup:di:compile-multi-tenant', verbosity: Logger::INFO
            else
              output = capture :magento, 'setup:di:compile', verbosity: Logger::INFO
            end

            # 2.0.x never returns a non-zero exit code for errors, so manually check string
            # 2.1.x doesn't return a non-zero exit code for certain errors (see davidalger/capistrano-magento2#41)
            if output.to_s.include? 'Errors during compilation'
              raise Exception, 'DI compilation command execution failed'
            end
          end
        end
      end
    end

    namespace 'static-content' do
      desc 'Deploys static view files'
      task :deploy do
        on release_roles :all do
          _magento_version = magento_version

          deploy_languages = fetch(:magento_deploy_languages).join(' ')
          deploy_themes = fetch(:magento_deploy_themes)

          if deploy_themes.count() > 0 and _magento_version >= Gem::Version.new('2.1.1')
            deploy_themes = deploy_themes.join(' -t ').prepend(' -t ')
          elsif deploy_themes.count() > 0
            warn "\e[0;31mWarning: the :magento_deploy_themes setting is only supported in Magento 2.1.1 and later\e[0m"
            deploy_themes = nil
          else
            deploy_themes = nil
          end

          # Output is being checked for a success message because this command may easily fail due to customizations
          # and 2.0.x CLI commands do not return error exit codes on failure. See magento/magento2#3060 for details.
          within release_path do

            # Workaround for 2.1 specific issue: https://github.com/magento/magento2/pull/6437
            execute "touch #{release_path}/pub/static/deployed_version.txt"

            # Generates all but the secure versions of RequireJS configs
            static_content_deploy "#{deploy_languages}#{deploy_themes}"
          end

          # Run again with HTTPS env var set to 'on' to pre-generate secure versions of RequireJS configs
          deploy_flags = ['javascript', 'css', 'less', 'images', 'fonts', 'html', 'misc', 'html-minify']
            .join(' --no-').prepend(' --no-');

          # Magento 2.1.0 and earlier lack support for these flags, so generation of secure files requires full re-run
          deploy_flags = nil if _magento_version <= Gem::Version.new('2.1.0')

          within release_path do with(https: 'on') {
            static_content_deploy "#{deploy_languages}#{deploy_themes}#{deploy_flags}"
          } end
        end
      end
    end
  end

  namespace :maintenance do
    desc 'Enable maintenance mode'
    task :enable do
      on release_roles :all do
        within release_path do
          execute :magento, 'maintenance:enable'
        end
      end
    end

    desc 'Disable maintenance mode'
    task :disable do
      on release_roles :all do
        within release_path do
          execute :magento, 'maintenance:disable'
        end
      end
    end

    desc 'Displays maintenance mode status'
    task :status do
      on release_roles :all do
        within release_path do
          execute :magento, 'maintenance:status'
        end
      end
    end

    desc 'Sets maintenance mode exempt IPs'
    task 'allow-ips', :ip do |t, args|
      on release_roles :all do
        within release_path do
          execute :magento, 'maintenance:allow-ips', args[:ip]
        end
      end
    end
  end

  namespace :indexer do
    desc 'Reindex data by all indexers'
    task :reindex do
      on primary fetch(:magento_deploy_setup_role) do
        within release_path do
          execute :magento, 'indexer:reindex'
        end
      end
    end

    desc 'Shows allowed indexers'
    task :info do
      on primary fetch(:magento_deploy_setup_role) do
        within release_path do
          execute :magento, 'indexer:info'
        end
      end
    end

    desc 'Shows status of all indexers'
    task :status do
      on primary fetch(:magento_deploy_setup_role) do
        within release_path do
          execute :magento, 'indexer:status'
        end
      end
    end

    desc 'Shows mode of all indexers'
    task 'show-mode', :index do |t, args|
      on primary fetch(:magento_deploy_setup_role) do
        within release_path do
          execute :magento, 'indexer:show-mode', args[:index]
        end
      end
    end

    desc 'Sets mode of all indexers'
    task 'set-mode', :mode, :index do |t, args|
      on primary fetch(:magento_deploy_setup_role) do
        within release_path do
          execute :magento, 'indexer:set-mode', args[:mode], args[:index]
        end
      end
    end
  end
end
