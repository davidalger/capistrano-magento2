##
 # Copyright © 2016 by David Alger. All rights reserved
 # 
 # Licensed under the Open Software License 3.0 (OSL-3.0)
 # See included LICENSE file for full text of OSL-3.0
 # 
 # http://davidalger.com/contact/
 ##

namespace :deploy do
  task :updated do
    on release_roles :all do
      invoke 'magento:composer:install'
      invoke 'magento:setup:permissions'
      invoke 'magento:setup:static_content:deploy'
      invoke 'magento:setup:di:compile'
      invoke 'magento:setup:permissions'
      within current_path do
        execute :magento, 'maintenance:enable'
      end
      invoke 'magento:maintenance:enable'
      invoke 'magento:setup:upgrade'
    end
  end

  task :published do
    on release_roles :all do
      invoke 'magento:cache:flush'
      invoke 'magento:cache:varnish:ban'    # TODO: this should not be needed after magento/magento2#3339 is released
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
