# Capistrano::Magento2 Change Log

0.8.9
=========

* Fixed issue with RabbitMQ settings caused by app:config:import running after setup-upgrade step vs prior to the database upgrades (which connects to RabbitMQ in recurring data upgrade scripts)

0.8.8
==========

* Added support for zero-side-effect pipeline deployments when scopes/themes have been dumped to config.php

0.8.7
==========

* Updated use of `touch` to run such that SSHKit prefixes may be used (PR #110)

0.8.6
==========

* Fixed possible race condition in `magento:deploy:version_check` when `app/etc/env.php` resides on an NFS share

0.8.5
==========

* Added ability to override flags sent to `composer install` to workaround issue in Magento 2.3 beta preventing deploy

0.8.4
==========

* Disabled call to `magento:setup:db:schema:upgrade` when running a zero-down deployment
* Disabled call to `magento:setup:db:data:upgrade` when running a zero-down deployment
* Fixed possible race condition in `magento:deploy:mode:production` when `app/etc/env.php` resides on an NFS share

0.8.3
==========

* Fixed regression failing deployment when `:magento_deploy_composer` is set to `false` (PR #106)

0.8.2
==========

* Added `var/export` to default list of :linked_dirs to support bundled `dotmailer/dotmailer-magento2-extension` package

0.8.1
==========

* Added `require 'capistrano/magento2/cachetool'` which may be used to enable flushing the php-opcache when [cachetool](http://gordalina.github.io/cachetool/) is installed on the server
* Added `cachetool:opcache:status` and `cachetool:opcache:reset` commands (use `require 'capistrano/magento2/cachetool'` to enable them)
* Fixed issue causing deployment to disable maintenance mode when manually enabled prior to deployment (issue #16)

0.8.0
==========

* Added support for zero-down deployment (PR #104, issue #34)
* Added call to "composer dump-autoload --no-dev --optimize" following DI compliation (issue #102)

0.7.3
==========

* Optimized set permissions operation (PR #89)
* Fixed `uninitialized constant Capistrano::Magento2::Setup::DateTime` error (PR #93, issue #92)

0.7.2
==========

* Added support for Magento 2.2 [static content deploy strategies](http://bit.ly/2yhMvVv) (PR #85)
* Added support for Magento 2.2 [shared application config files](http://bit.ly/2gF8Ouu) (issue #83)

0.7.1
==========

* Fixed deploy routine so production mode is no longer enabled automatically when `:magento_deploy_production` is false
* Fixed regression in multi-lingual deployment (reverted boxing workaround with 2.1.7 upper limit; release notes are wrong and the issue persists in 2.1.8)
* Updated double run of static content deploy to only apply to versions prior to 2.1.8 (underling issue was resolved in 2.1.8)

0.7.0
==========

* Added support for Magento 2.2.0 release candidates
* Removed support for deployment of Magento versions older than 2.1.1
* Updated and optimized static content deployment for upcoming Magento 2.2.0 release
* Updated composer install routine; --no-dev is now used indiscriminately since Magento 2.1.1 and later support it; no more duplicate composer install commands (issue #76)
* Updated multi-lingual site deployment workaround to apply only to versions 2.1.3 through 2.1.7 as per 2.1.8 release notes the underlying issue has been resolved (issue #72)
* Added tasks to set production mode and show current mode (magento:deploy:mode:production and magento:deploy:mode:show)

0.6.6
==========

* Updated date formatting of pending change log output for enhanced readability (PR #73)
* Fixed bug in static content deploy resulting from a change in behaviour in Magento 2.1.3 and later (PR #74)

0.6.5
==========

* Added workaround for Magento 2.1.3 bug causing multi-lingual static-content deployment failure (issue #72)

0.6.4
==========

* Added support for the config.local.php file found in Magento 2.1.6 and later

0.6.3
==========

* Fixed deployment to multiple hosts resulting in disparate static content versions across target hosts

0.6.2
==========

* Added setting `:magento_deploy_jobs` to support configuring number of parallel static content deployment tasks
* Fixed issue where ./update dir may exist without a composer.json file, causing deployment failure
* Updated uses of bin/magento where output is parsed to include `--no-ansi` to eliminate potential failures
* Improved error reporting on static content deployment failure

0.6.1
==========

* Fixed Magento version check failing on some servers due to ansi output in non-interactive shells (issue #64)
* Added ability to configure Magento's composer authentication keys. See README for details (PR #56)
* Changed pending change log to hook into before `deploy:check` (previously hooked before `deploy`)

0.6.0
==========

* Added full-featured pending change logging functionality. See README for details (issue #58)
* Fixed inability to set PATH in capistrano configuration vs `.bashrc` file (issue #62)
* Updated README to reflect removing the `terminal-notifier` gem as a hard dependency (issue #19)
* Removed `capistrano-pending` as a dependency (issue #58)

0.5.9
==========

* Updated README with Capistrano 3.7 setup information
* Updated `linked_dirs` to link `pub/sitemaps` by default in similar fashion to the Magento1 deployment gem
* Updated README with guidance on adding a path to the list of `linked_dirs` without copying the entire configuration forward
* Fixed bug causing pipefail option to persist after `Capistrano::Magento2::Setup.static_content_deploy` is called
 
0.5.8
==========

* Fixed critical failure due to command map being broken in v0.5.7 updates (issue #50, issue #51)

0.5.7
==========
_Note: This release was yanked from RubyGems due to a critical failure in the deploy routine._

* Fixed failing deploys for Magento 2.1.0 caused by improper version checks on flags added in version 2.1.1 (issue #45)
* Fixed failure to detect error codes Magento 2.1.1 returns on a failed static-content deploy job (issue #44)

0.5.6
==========

* Fixed issue where setup:di:compile failing to return an exit code caused DI compilation failures to be masked (issue #41)

0.5.5
==========

* Fixed DI artifact mismatch caused by setup:ugprade overwriting frozen config.php post compilation
* Removed redundant (and non-functional) commands from deploy:reverted task
* Added informational output which lists the installed modules which are disabled per `app/etc/config.php`

0.5.4
==========

* Fixed issue causing failed releases when there are CSS compilation errors in setup:static-content:deploy task
* Updated static content deployment to ignore `:magento_deploy_themes` when deploying 2.0 and issue a warning message.

0.5.3
==========

* Added setting `:magento_deploy_cache_shared` for targeting cache related tasks (issue #33)
* Added setting `:magento_deploy_setup_role` for targeting setup related tasks (issue #33)
* Fixed magento setup, cache, index commands to only run on appropriate node(s) in multi-node deploys (issue #33).
* Fixed capistrano-pending support to play nicely with multiple hosts. Now only performs check on a single host.
* Updated `magento:deploy:verify` output with host specific messaging on configuration errors.

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
