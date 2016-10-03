# Capistrano::Magento2 Change Log

0.5.2
==========

* Added ability to configure permissions set on each deploy (issue #32). See README for details.

0.5.1
==========

* Fixed usability regression causing deploy confirmation to occur prior to display of `capistrano/magento2/pending` output when in use (issue #28)
* Fixed "REVISION file doesn't exist" error when deploying for the first time when `capistrano/magento2/pending` is loaded
* Fixed issue breaking initial deploy when `:magento_deploy_maintenance` is set to true

0.5.0
==========

* Added ability to only deploy specific themes via the new `:magento_deploy_themes` array
* Added `:magento_deploy_confim` setting which requires user confirmation of deployment to specific capistrano stages
* Added call to pre-generate secure RequireJS config (issue #21)
* Added workaround for Magento 2.1 specific bug where lack of a deployed_version.txt file would fail static asset deploy
* Added error check on output of setup:di:compile-multi-tenant since Magento 2.0 doesn't return error codes (issue #25)
* Updated formatting of pending deployment messaging
* Updated composer calls to specify --no-dev and --optimize-autoloader when `:magento_deploy_production` is not set (issue #22, #23)
* Fixed bug causing maintenance mode to be enabled on deploy even when `:magento_deploy_maintenance` was set to false
* Fixed bug preventing the second call to `magento:setup:permissions` from being executed (issue #18)
* Removed the undocumented `:deploy_warn_stages` setting from the notifier

0.4.0
==========

* Added optional support for capistrano-pending gem.
* Added `:magento_deploy_composer` flag. See README for details.
* Added `:magento_deploy_maintenance` flag. See README for details.
* Updated `:magento_deploy_languages` definition to explicitly declare default value.

0.3.0
==========

* Added `:magento_deploy_production` flag to disable production deploy commands (PR #10 by @giacmir).
* Added `:magento_deploy_languages` setting to support passing language list to static content generator (PR #11 by @giacmir).

0.2.4
==========

* Added internal `magento:deploy:check` task and `:linked_files_touch` setting to minimize manual server setup
* Moved default linked file for sitemap.xml into pub directory

0.2.3
==========

* Added file check to halt deploy if app/etc/config.php is not present in repository
* Added check to verify that app/etc/env.php contains an array with an install date

0.2.2
==========

* Revert "Add workaround for M2.0.4 bug noted in magento/magento2#4070"

0.2.1
==========

* Fixed issue with initial deploy failing before 'current' link has been created on target

0.2.0
==========

* Added "smart" magento:setup:di:compile task which uses multi-tenant if available (for compatibility with 2.0 release)
* Added a command_map for the bin/magento tool to simplify rake files
* Added indexer:info, indexer:status, indexer:show-mode, indexer:set-mode
* Added maintenance:status and maintenance:allow-ips, exposes maintenance:disable
* Fixed broken error detection logic on setup:static-content:deploy
* Fixed bug where magento:setup:upgrade was not using the --keep-generated flag
* Fixed log bloat caused by chatty static-content:deploy
* Fixed missing dependency include in deploy.rb
* Fixed output of magento:cache:varnish:ban command
* Fixed potential issue where if a botched release was in production, one could not roll back
* Fixed technical dependency bug preventing projects from overriding the deploy.rake with a custom one
* Renamed capistrano/magento2/deploy/notify to capistrano/magento2/notifier
* Renamed magento:reset_permissions to magento:setup:permissions
* Renamed magento:setup:static_content:deploy to magento:setup:static-content:deploy
* Updated composer calls to explicitly set  --prefer-dist and --no-interaction
* Updated README to reflect current setup instructions

0.1.3
==========

* Changed magento:cache:varnish:ban to use `:varnish_cache_hosts` array in deploy config vs hardcoding 127.0.0.1:6081

0.1.2
==========

* Added information to README file regarding use of terminal-notifier functionality

0.1.1
==========

* Initial functional release, tested with Magento 2.0.4 / PHP 7.0.5
