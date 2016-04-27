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
      desc 'Add ban to Varnish for url(s)'
      task :ban do
        on release_roles :all do
          next unless any? :ban_pools
          next unless any? :varnish_cache_hosts
          
          within release_path do
            for pool in fetch(:ban_pools) do
              for cache_host in fetch(:varnish_cache_hosts) do
                execute :curl, %W{-H 'X-Pool: #{pool}' -X PURGE #{cache_host}}
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
          execute :composer, 'install --prefer-dist --no-interaction 2>&1'
            
          # Dir should be here if properly setup, but check for it anyways just in case
          if test "[ -d #{release_path}/update ]"
            execute :composer, 'install --prefer-dist --no-interaction -d ./update 2>&1'
          else
            puts "\e[0;31m    Warning: ./update dir does not exist in repository!\n\e[0m\n"
          end
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
    
    namespace :di do
      task :compile do
        on release_roles :all do
          within release_path do
            execute :magento, 'setup:di:compile'
          end
        end
      end
      
      task :compile_multi_tenant do
        on release_roles :all do
          within release_path do
            execute :magento, '-q setup:di:compile-multi-tenant'
            execute :rm, '-f var/di/relations.ser'   # TODO: Workaround broken DI compilation on PHP 7.0.5 (GH #4070)
          end
        end
      end
    end
    
    namespace :static_content do
      task :deploy do
        on release_roles :all do
          within release_path do
            
            # TODO: Remove custom error detection logic once magento/magento2#3060 is resolved
            # Currently the cli tool is not reporting failures via the exit code, so manual detection is neccesary
            output = capture :magento, 'setup:static-content:deploy | stdbuf -o0 tr -d .', verbosity: Logger::INFO
            
            if output.to_s.include? 'Compilation from source'
              puts "\n\e[0;31m" \
                "    ######################################################################\n" \
                "    #                                                                    #\n" \
                "    #                 Failed to compile static assets                    #\n" \
                "    #                                                                    #\n" \
                "    ######################################################################\n\n"
              puts output + "\e[0m\n"
              raise Exception, 'Failed to compile static assets'
            end
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
    
    task :disable do
      on release_roles :all do
        within release_path do
          execute :magento, 'maintenance:disable'
        end
      end
    end
  end
  
  desc 'Reset permissions'
  task :reset_permissions do
    on release_roles :all do
      within release_path do
        execute :find, release_path, '-type d -exec chmod 770 {} +'
        execute :find, release_path, '-type f -exec chmod 660 {} +'
        execute :chmod, '-R g+s', release_path
        execute :chmod, '+x ./bin/magento'
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
  end

end

namespace :load do
  task :defaults do

    SSHKit.config.command_map[:magento] = "/usr/bin/env php -f bin/magento --"

    set :linked_files, fetch(:linked_files, []).push(
      'app/etc/env.php',
      'var/.setup_cronjob_status',
      'var/.update_cronjob_status',
      'sitemap.xml'
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
  end
end
