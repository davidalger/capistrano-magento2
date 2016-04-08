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
    desc 'Flush the Magento Cache'
    task :flush do
      on release_roles :all do
        within release_path do
          execute :php, '-f', 'bin/magento', '--', 'cache:flush'
        end
      end
    end
    
    namespace :varnish do
      desc 'Add ban to Varnish for url(s)'
      task :ban do
        on release_roles :all do
          within release_path do
            # TODO: set default value for this parameter so if not set by site config, this won't fail
            # TODO: change this to a more unique name
            for url in fetch(:urls) do
              varnish_response = capture(:curl, '-v', '-k', '-H', %'"X-Host: #{url}"', '-X', 'BAN', '127.0.0.1:6081')
              if varnish_response.include? '<title>200 Banned</title>'
                puts '    200 Banned: ' + url
              elsif
                puts "\n\e[0;31m" \
                  "    ######################################################################\n" \
                  "    #                                                                    #\n" \
                  "    #                    Failed to ban Varnish urls                      #\n" \
                  "    #                                                                    #\n" \
                  "    ######################################################################\n\n"
                puts varnish_response
                puts "\e[0m\n"
              end
            end
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
          execute :php, '-f', 'bin/magento', '--', 'setup:upgrade'
        end
      end
    end

    # TODO: Change this once the bug with single tenant compiler is fixed http://devdocs.magento.com/guides/v2.0/config-guide/cli/config-cli-subcommands-compiler.html#config-cli-subcommands-single
    namespace :di do
      task :compile_multi_tenant do
        on release_roles :all do
          within release_path do
            execute :php, '-f', 'bin/magento', '--', 'setup:di:compile-multi-tenant', '-q'
          end
        end
      end
    end
    
    namespace :static_content do
      task :deploy do
        on release_roles :all do
          within release_path do
            
            # Due to a bug (https://github.com/magento/magento2/issues/3060) in bin/magento, errors in the
            # compilation will not result in a non-zero exit code, so Capistrano is not aware an error has occurred.
            # As a result, we must capture the output and manually search for an error string to determine whether
            # compilation is successful. Once the aforementioned bug is fixed, pass a "-q" flag to
            # 'setup:static-content:deploy' to silence verbose output, as right now the log is being filled with
            # thousands of extraneous lines, per this issue: https://github.com/magento/magento2/issues/3692
            
            set :static_content_deploy_output, capture(:php, '-f', 'bin/magento', '--', 'setup:static-content:deploy')
            
            if fetch(:static_content_deploy_output).to_s.include? 'Compilation from source'
              
              # TODO: add method to output heading messages such as this
              puts "\n\e[0;31m" \
                "    ######################################################################\n" \
                "    #                                                                    #\n" \
                "    #                 Failed to compile static assets                    #\n" \
                "    #                                                                    #\n" \
                "    ######################################################################\n\n"
              puts fetch(:static_content_deploy_output)
              puts "\e[0m\n"
              
              raise Exception, 'Failed to compile static assets'
            else
              puts '    Static content compilation successful'
            end
          end
        end
      end
    end
  end
  
  desc 'Reset permissions'
  task :reset_permissions do
    on release_roles :all do
      within release_path do
        execute :find, '.', '-type', 'd', '-exec', 'chmod', '770', '{}', '+'
        execute :find, '.', '-type', 'f', '-exec', 'chmod', '660', '{}', '+'
        execute :chmod, '-R', 'g+s', '.'
        execute :chmod, '+x', './bin/magento'
      end
    end
  end

  namespace :indexer do
    desc 'Reindex data by all indexers'
    task :reindex do
      on release_roles :all do
        within "#{release_path}" do
          execute :php, '-f', 'bin/magento', '--', 'indexer:reindex'
        end
      end
    end
  end

end
