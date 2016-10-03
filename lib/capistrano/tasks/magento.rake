##
 # Copyright © 2016 by David Alger. All rights reserved
 # 
 # Licensed under the Open Software License 3.0 (OSL-3.0)
 # See included LICENSE file for full text of OSL-3.0
 # 
 # http://davidalger.com/contact/
 ##

namespace :magento do
  
  namespace :cache do
    desc 'Flush Magento cache storage'
    task :flush do
      on release_roles :all do
        within release_path do
          execute :magento, 'cache:flush'
        end
      end
    end
    
    desc 'Clean Magento cache by types'
    task :clean do
      on release_roles :all do
        within release_path do
          execute :magento, 'cache:clean'
        end
      end
    end
    
    desc 'Enable Magento cache'
    task :enable do
      on release_roles :all do
        within release_path do
          execute :magento, 'cache:enable'
        end
      end
    end
    
    desc 'Disable Magento cache'
    task :disable do
      on release_roles :all do
        within release_path do
          execute :magento, 'cache:disable'
        end
      end
    end
    
    desc 'Check Magento cache enabled status'
    task :status do
      on release_roles :all do
        within release_path do
          execute :magento, 'cache:status'
        end
      end
    end
  
    namespace :varnish do
      # TODO: Document what the magento:cache:varnish:ban task is for and how to use it. See also magento/magento2#4106
      desc 'Add ban to Varnish for url(s)'
      task :ban do
        on release_roles :all do
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

          if fetch(:magento_deploy_production)
            feature_version = capture :magento, "-V | cut -d' ' -f4 | cut -d. -f1-2"
            
            if feature_version.to_f > 2.0
              composer_flags += ' --no-dev'
              execute :composer, "install #{composer_flags} 2>&1" # removes require-dev components from prev command
            end
          end

          if test "[ -d #{release_path}/update ]"   # can't count on this, but emit warning if not present
            execute :composer, "install #{composer_flags} -d ./update 2>&1"
          else
            puts "\e[0;31m    Warning: ./update dir does not exist in repository!\n\e[0m\n"
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
      on release_roles :all do
        unless test "[ -f #{release_path}/app/etc/config.php ]"
          error "The repository is missing app/etc/config.php. Please install the application and retry!"
          exit 1
        end

        unless test %Q[#{SSHKit.config.command_map[:php]} -r '
              $cfg = include "#{release_path}/app/etc/env.php";
              exit((int)!isset($cfg["install"]["date"]));
          ']
          error "No environment configuration could be found. Please configure app/etc/env.php and retry!"
          exit 1
        end
      end
    end
  end

  namespace :setup do
    desc 'Run the Magento upgrade process'
    task :upgrade do
      on release_roles :all do
        within release_path do
          execute :magento, 'setup:upgrade --keep-generated'
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
              
              if output.to_s.include? 'Errors during compilation'
                raise Exception, 'setup:di:compile-multi-tenant command execution failed'
              end
            else
              execute :magento, 'setup:di:compile'
            end
          end
        end
      end
    end
    
    namespace 'static-content' do
      desc 'Deploys static view files'
      task :deploy do
        on release_roles :all do
          deploy_languages = fetch(:magento_deploy_languages).join(' ')
          deploy_themes = fetch(:magento_deploy_themes)

          if deploy_themes.count() > 0
            deploy_themes = ' -t ' + deploy_themes.join(' -t ')   # prepare value for cli command if theme(s) specified
          else
            deploy_themes = ''
          end

          # Output is being checked for a success message because this command may easily fail due to customizations
          # and 2.0.x CLI commands do not return error exit codes on failure. See magento/magento2#3060 for details.
          within release_path do

            # Workaround for 2.1 specific issue: https://github.com/magento/magento2/pull/6437
            execute "touch #{release_path}/pub/static/deployed_version.txt"

            output = capture :magento,
              "setup:static-content:deploy #{deploy_languages}#{deploy_themes} | stdbuf -o0 tr -d .",
              verbosity: Logger::INFO

            if not output.to_s.include? 'New version of deployed files'
              raise Exception, 'Failed to compile static assets'
            end

            with(https: 'on') {
              deploy_flags = ''

              # Magento 2.0 does not have these flags, so only way to generate secure files is to do all of them :/
              if test :magento, 'setup:static-content:deploy --help | grep -- --theme'
                deploy_flags = " --no-javascript --no-css --no-less --no-images" \
                  + " --no-fonts --no-html --no-misc --no-html-minify"
              end

              output = capture :magento,
                "setup:static-content:deploy #{deploy_languages}#{deploy_themes}#{deploy_flags} | stdbuf -o0 tr -d .",
                verbosity: Logger::INFO

              if not output.to_s.include? 'New version of deployed files'
                raise Exception, 'Failed to compile (secure) static assets'
              end
            }
          end
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
      on release_roles :all do
        within release_path do
          execute :magento, 'indexer:reindex'
        end
      end
    end

    desc 'Shows allowed indexers'
    task :info do
      on release_roles :all do
        within release_path do
          execute :magento, 'indexer:info'
        end
      end
    end

    desc 'Shows status of all indexers'
    task :status do
      on release_roles :all do
        within release_path do
          execute :magento, 'indexer:status'
        end
      end
    end

    desc 'Shows mode of all indexers'
    task 'show-mode', :index do |t, args|
      on release_roles :all do
        within release_path do
          execute :magento, 'indexer:show-mode', args[:index]
        end
      end
    end

    desc 'Sets mode of all indexers'
    task 'set-mode', :mode, :index do |t, args|
      on release_roles :all do
        within release_path do
          execute :magento, 'indexer:set-mode', args[:mode], args[:index]
        end
      end
    end
  end

end

namespace :load do
  task :defaults do

    SSHKit.config.command_map[:magento] = "/usr/bin/env php -f bin/magento --"

    set :linked_files, fetch(:linked_files, []).push(
      'app/etc/env.php',
      'var/.setup_cronjob_status',
      'var/.update_cronjob_status',
      'pub/sitemap.xml'
    )

    set :linked_files_touch, fetch(:linked_files_touch, []).push(
      'app/etc/env.php',
      'var/.setup_cronjob_status',
      'var/.update_cronjob_status',
      'pub/sitemap.xml'
    )

    set :linked_dirs, fetch(:linked_dirs, []).push(
      'pub/media', 
      'var/backups', 
      'var/composer_home', 
      'var/importexport', 
      'var/import_history', 
      'var/log',
      'var/session', 
      'var/tmp'
    )

    set :magento_deploy_languages, fetch(:magento_deploy_languages, ['en_US'])
    set :magento_deploy_themes, fetch(:magento_deploy_themes, [])
    set :magento_deploy_chmod_d, fetch(:magento_deploy_chmod_d, '2770')
    set :magento_deploy_chmod_f, fetch(:magento_deploy_chmod_f, '0660')
    set :magento_deploy_chmod_x, fetch(:magento_deploy_chmod_x, ['bin/magento'])
  end
end
