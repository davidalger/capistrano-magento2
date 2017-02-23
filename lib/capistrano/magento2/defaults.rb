##
 # Copyright © 2016 by David Alger. All rights reserved
 # 
 # Licensed under the Open Software License 3.0 (OSL-3.0)
 # See included LICENSE file for full text of OSL-3.0
 # 
 # http://davidalger.com/contact/
 ##

set :linked_files, fetch(:linked_files, []).push(
  'app/etc/env.php',
  'var/.setup_cronjob_status',
  'var/.update_cronjob_status'
)

set :linked_files_touch, fetch(:linked_files_touch, []).push(
  'app/etc/env.php',
  'var/.setup_cronjob_status',
  'var/.update_cronjob_status'
)

set :linked_dirs, fetch(:linked_dirs, []).push(
  'pub/media',
  'pub/sitemaps',
  'var/backups', 
  'var/composer_home', 
  'var/importexport', 
  'var/import_history', 
  'var/log',
  'var/session', 
  'var/tmp'
)

# deploy permissions defaults
set :magento_deploy_chmod_d, fetch(:magento_deploy_chmod_d, '2770')
set :magento_deploy_chmod_f, fetch(:magento_deploy_chmod_f, '0660')
set :magento_deploy_chmod_x, fetch(:magento_deploy_chmod_x, ['bin/magento'])

# deploy configuration defaults
set :magento_deploy_composer, fetch(:magento_deploy_composer, true)
set :magento_deploy_confirm, fetch(:magento_deploy_confirm, [])
set :magento_deploy_languages, fetch(:magento_deploy_languages, ['en_US'])
set :magento_deploy_maintenance, fetch(:magento_deploy_maintenance, true)
set :magento_deploy_production, fetch(:magento_deploy_production, true)
set :magento_deploy_themes, fetch(:magento_deploy_themes, [])

# deploy targetting defaults
set :magento_deploy_setup_role, fetch(:magento_deploy_setup_role, :all)
set :magento_deploy_cache_shared, fetch(:magento_deploy_cache_shared, true)

# set capistrano-pending defaults to match this gem's expectations
set :capistrano_pending_role, fetch(:magento_deploy_setup_role)
