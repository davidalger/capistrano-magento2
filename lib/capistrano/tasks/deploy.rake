##
 # Copyright © 2016 by David Alger. All rights reserved
 # 
 # Licensed under the Open Software License 3.0 (OSL-3.0)
 # See included LICENSE file for full text of OSL-3.0
 # 
 # http://davidalger.com/contact/
 ##

namespace :deploy do
  before 'deploy:check:linked_files', 'magento:deploy:check'

  task :updated do
    on release_roles :all do
      invoke 'magento:deploy:verify'
      invoke 'magento:composer:install'
      invoke 'magento:setup:permissions'
      invoke 'magento:setup:static-content:deploy'
      invoke 'magento:setup:di:compile'
      invoke 'magento:setup:permissions'
      if test '-d #{current_path}'
        within current_path do
          execute :magento, 'maintenance:enable'
        end
      end
      invoke 'magento:maintenance:enable'
      invoke 'magento:setup:upgrade'
    end
  end

  task :published do
    on release_roles :all do
      invoke 'magento:cache:flush'
      invoke 'magento:cache:varnish:ban'
      invoke 'magento:maintenance:disable'
    end
  end

  task :reverted do
    on release_roles :all do
      invoke 'magento:maintenance:disable'
      invoke 'magento:cache:flush'
      invoke 'magento:cache:varnish:ban'
    end
  end
end
