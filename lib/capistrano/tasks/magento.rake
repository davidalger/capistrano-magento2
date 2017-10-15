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

  namespace :app do
    namespace :config do
      desc 'Create dump of application config'
      task :dump do
        on primary fetch(:magento_deploy_setup_role) do
          within release_path do
            execute :magento, 'app:config:dump'
          end
        end
      end
      
      desc 'Import data from shared config files'
      task :import do
        on primary fetch(:magento_deploy_setup_role) do
          within release_path do
            execute :magento, 'app:config:import'
          end
        end
      end
    end
  end

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
    task :install => :auth_config do

      on release_roles :all do
        within release_path do
          composer_flags = '--no-dev --prefer-dist --no-interaction'

          if fetch(:magento_deploy_production)
            composer_flags += ' --optimize-autoloader'
          end

          execute :composer, "install #{composer_flags} 2>&1"

          if test "[ -f #{release_path}/update/composer.json ]"   # can't count on this, but emit warning if not present
            execute :composer, "install #{composer_flags} -d ./update 2>&1"
          else
            puts "\e[0;31m    Warning: ./update/composer.json does not exist in repository!\n\e[0m\n"
          end
        end
      end
    end

    task :auth_config do
      on release_roles :all do
        within release_path do
          if fetch(:magento_auth_public_key) and fetch(:magento_auth_private_key)
            execute :composer, :config, '-q',
              fetch(:magento_auth_repo_name),
              fetch(:magento_auth_public_key),
              fetch(:magento_auth_private_key),
              verbosity: Logger::DEBUG
          end
        end
      end
    end
  end

  namespace :deploy do
    namespace :mode do
      desc "Enables production mode"
      task :production do
        on release_roles :all do
          within release_path do
            execute :magento, "deploy:mode:set production --skip-compilation"
          end
        end
      end
      
      desc "Displays current application mode"
      task :show do
        on release_roles :all do
          within release_path do
            execute :magento, "deploy:mode:show"
          end
        end
      end
    end

    task :version_check do
      on release_roles :all do
        within release_path do
          _magento_version = magento_version
          unless _magento_version >= Gem::Version.new('2.1.1')
            error "\e[0;31mVersion 0.7.0 and later of this gem only support deployment of Magento 2.1.1 or newer; " +
              "attempted to deploy v" + _magento_version.to_s + ". Please try again using an earlier version of this gem!\e[0m"
            exit 1  # only need to check a single server, exit immediately
          end
        end
      end
    end

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

    task :local_config do
      on release_roles :all do
        if test "[ -f #{release_path}/app/etc/config.local.php ]"
          info "The repository contains app/etc/config.local.php, removing from :linked_files list."
          _linked_files = fetch(:linked_files, [])
          _linked_files.delete('app/etc/config.local.php')
          set :linked_files, _linked_files
        end
      end
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
            db_status = capture :magento, 'setup:db:status --no-ansi', verbosity: Logger::INFO
            
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
            output = capture :magento, 'setup:di:compile --no-ansi', verbosity: Logger::INFO

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

          deploy_themes = fetch(:magento_deploy_themes)
          deploy_jobs = fetch(:magento_deploy_jobs)

          if deploy_themes.count() > 0
            deploy_themes = deploy_themes.join(' -t ').prepend(' -t ')
          else
            deploy_themes = nil
          end

          if deploy_jobs
            deploy_jobs = "--jobs #{deploy_jobs} "
          else
            deploy_jobs = nil
          end

          # Workaround core-bug with multi-lingual deployments on Magento 2.1.3 and greater. In these versions each
          # language must be iterated individually. See issue #72 for details.
          if _magento_version >= Gem::Version.new('2.1.3')
            deploy_languages = fetch(:magento_deploy_languages)
          else
            deploy_languages = [fetch(:magento_deploy_languages).join(' ')]
          end

          # Magento 2.2 introduced static content compilation strategies that can be one of the following:
          # quick (default), standard (like previous versions) or compact
          compilation_strategy = fetch(:magento_deploy_strategy)
          if compilation_strategy and _magento_version >= Gem::Version.new('2.2.0')
              compilation_strategy =  "-s #{compilation_strategy} "
          else
            compilation_strategy = nil
          end

          within release_path do
            # Magento 2.1 will fail to deploy if this file does not exist and static asset signing is enabled
            execute "touch #{release_path}/pub/static/deployed_version.txt"

            # This loop exists to support deploy on versions where each language must be deployed seperately
            deploy_languages.each do |lang|
              static_content_deploy "#{compilation_strategy}#{deploy_jobs}#{lang}#{deploy_themes}"
            end
          end

          # Run again with HTTPS env var set to 'on' to pre-generate secure versions of RequireJS configs. A
          # single run on these Magento versions will fail to generate the secure requirejs-config.js file.
          if _magento_version < Gem::Version.new('2.1.8')
            deploy_flags = ['css', 'less', 'images', 'fonts', 'html', 'misc', 'html-minify']
              .join(' --no-').prepend(' --no-');

            within release_path do with(https: 'on') {
              # This loop exists to support deploy on versions where each language must be deployed seperately
              deploy_languages.each do |lang|
                static_content_deploy "#{compilation_strategy}#{deploy_jobs}#{lang}#{deploy_themes}#{deploy_flags}"
              end
            } end
          end

          # Set the deployed_version of static content to ensure it matches across all hosts
          upload!(StringIO.new(deployed_version), "#{release_path}/pub/static/deployed_version.txt")
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
