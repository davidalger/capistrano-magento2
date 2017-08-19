# Capistrano::Magento2

[![Gem Version](https://badge.fury.io/rb/capistrano-magento2.svg)](https://badge.fury.io/rb/capistrano-magento2)

A Capistrano extension for Magento 2 deployments. Takes care of specific Magento 2 requirements and adds tasks specific to the Magento 2 application.

## Supported Magento Versions

**As of version 0.7.0 this gem only supports deployment of Magento 2.1.1 or later; please use an earlier version to deploy older releases of Magento 2**

## Installation

### Standalone Installation

    $ gem install capistrano-magento2

### Using Bundler

1. Add the following to your project's `Gemfile`:

    ```ruby
    source 'https://rubygems.org'
    gem 'capistrano-magento2'
    ```

2. Execute the following:

        $ bundle install

## Usage

1. Install Capistrano in your Magento project:
    
    ```shell
    $ cd <project_root>
    $ mkdir -p tools/cap
    $ cd ./tools/cap
    $ cap install
    ```
_Note: By default, Capistrano creates "staging" and "production" stages. If you want to define custom staging areas, you can do so using the "STAGES" option (e.g. `cap install STAGES=stage,prod`). Built-in notifications ([see below](#terminal-notifier-on-os-x)) confirm deploy action on both "production" and "prod" area names by default._

2. Update your project's `Capfile` to look like the following:

    ```ruby
    # Load DSL and set up stages
    require 'capistrano/setup'
    
    # Load Magento deployment tasks
    require 'capistrano/magento2/deploy'
    require 'capistrano/magento2/pending'
    
    # Load Git plugin
    require "capistrano/scm/git"
    install_plugin Capistrano::SCM::Git
    
    # Load custom tasks from `lib/capistrano/tasks` if you have any defined
    Dir.glob('lib/capistrano/tasks/*.rake').each { |r| import r }
    ```

3. Configure Capistrano, per the [Capistrano Configuration](#capistrano-configuration) section below.

4. Configure your server(s), per the [Server Configuration](#server-configuration) section below.

5. Deploy Magento 2 to staging or production by running the following command in the `tools/cap` directory:
    
    ```shell
    $ cap staging deploy
    ```
    or
    ```shell
    $ cap production deploy
    ```
    
## Default Configuration

### Capistrano Configuration

Before you can use Capistrano to deploy, you must configure the `config/deploy.rb` and `config/deploy/*.rb` files. This section will cover the basic details for configuring these files. Refer to the [Capistrano documentation](http://capistranorb.com/documentation/getting-started/preparing-your-application/#configure-your-server-addresses-in-the-generated-files) and [README](https://github.com/capistrano/capistrano/blob/master/README.md) for more details.

1. Configuring `config/deploy.rb`
    
    Update the `:application` and `:repo_url` values in `config/deploy.rb`:
    
    ```ruby
    # Something unique such as the website or company name
    set :application, 'example'
    # The repository that hosts the Magento 2 application (Magento should live in the root of the repo)
    set :repo_url, 'git@github.com:acme/example-com.git'
    ```

2. Configuring `config/deploy/*.rb` files
    
    Capistrano allows you to use server-based or role-based syntax. You can read through the comments in the file to learn more about each option. If you have a single application server then the server-based syntax is the simplest configuration option.
    
    * Single application server
        
        If your stage and production environments consist of a single application server, your configuration files should look something like this:
        
        `config/deploy/production.rb`
        ```ruby
        server 'www.example.com', user: 'www-data', roles: %w{app db web}
        
        set :deploy_to, '/var/www/html'
        set :branch, proc { `git rev-parse --abbrev-ref master`.chomp }
        ```
        
        `config/deploy/staging.rb`
        ```ruby
        server 'stage.example.com', user: 'www-data', roles: %w{app db web}
        
        set :deploy_to, '/var/www/html'
        set :branch, proc { `git rev-parse --abbrev-ref develop`.chomp }
        ```
        
    * Multiple application servers
        
        Refer to the "role-based syntax" comments in the `config/deploy/*.rb` files or to the [Capistrano documentation](http://capistranorb.com/documentation/getting-started/preparing-your-application/#configure-your-server-addresses-in-the-generated-files) for details on how to configure multiple application servers.

### Magento Deploy Settings

| setting                        | default | what it does
| ------------------------------ | ------- | ---
| `:magento_deploy_setup_role`   | `:all`  | Role from which primary host is chosen to run things like setup:upgrade on
| `:magento_deploy_cache_shared` | `true`  | If true, cache operations are restricted to the primary node in setup role
| `:magento_deploy_languages`    | `['en_US']` | Array of languages passed to static content deploy routine
| `:magento_deploy_themes`       | `[]`   | Array of themes passed to static content deploy
| `:magento_deploy_jobs`         | `4`    | Number of threads to use for static content deploy
| `:magento_deploy_composer`     | `true` | Enables composer install behaviour in the built-in deploy routine
| `:magento_deploy_production`   | `true` | Enables production specific DI compilation and static content generation
| `:magento_deploy_maintenance`  | `true` | Enables use of maintenance mode while magento:setup:upgrade runs
| `:magento_deploy_confirm`      | `[]`   | Used to require confirmation of deployment to a set of capistrano stages
| `:magento_deploy_chmod_d`      | `2770` | Default permissions applied to all directories in the release path
| `:magento_deploy_chmod_f`      | `0660` | Default permissions applied to all non-executable files in the release path
| `:magento_deploy_chmod_x`      | `['bin/magento']` | Default list of files in release path to set executable bit on

#### Example Usage

Add a line similar to the following in `config/deploy.rb` to set a custom value on one of the above settings:

```ruby
set :magento_deploy_languages, ['en_US', 'en_CA']
```

```ruby
set :magento_deploy_composer, false
```

### Capistrano Built-Ins

For the sake of simplicity in new project setups `:linked_dirs` and `:linked_files` are pre-configured per the following.

```ruby
set :linked_files, [
  'app/etc/env.php',
  'app/etc/config.local.php',
  'var/.setup_cronjob_status',
  'var/.update_cronjob_status'
]

set :linked_dirs, [
  'pub/media',
  'pub/sitemaps',
  'var/backups', 
  'var/composer_home', 
  'var/importexport', 
  'var/import_history', 
  'var/log',
  'var/session', 
  'var/tmp'
]
```

If you would like to customize the linked files or directories for your project, you can copy either one or both of the above arrays into the `config/deploy.rb` or `config/deploy/*.rb` files and tweak them to fit your project's needs. Alternatively, you can add a single linked dir (or file) using `append` like this:

```ruby
append :linked_dirs, 'path/to/link'
```

Support for a `app/etc/config.local.php` configuration file was added to Magento 2.1.6. This file will be linked in from the `shared/app/etc` directory as of v0.6.4 of this gem. If this file is present in the project repository, the file will not be linked.

### Composer Auth Credentials

Magento 2's composer repository requires auth credentials to install. These can be set on target servers in a global composer `auth.json` file, the project's `composer.json` or by setting them in your deployment configuration using the following two settings:

```ruby
set :magento_auth_public_key, '<your_public_key_here>'
set :magento_auth_private_key, '<your_prviate_key_here>'
```

To obtain these credentials, reference the official documentation on DevDocs: [Get your authentication keys](http://devdocs.magento.com/guides/v2.0/install-gde/prereq/connect-auth.html)

**Caution:** When using these settings, the values will be logged to the `log/capistrano.log` file by SSHKit. They will not, however, be included in the general command output by default.

### Magento 2 Deploy Routine

A pre-built deploy routine is available out-of-the-box. This can be overriden on a per-project basis by including only the Magento 2 specific tasks and defining your own `deploy.rake` file under `lib/capistrano/tasks` in your projects Capistrano install location.

To see what process the built-in routine runs, take a look at the included rake file here: https://github.com/davidalger/capistrano-magento2/blob/master/lib/capistrano/tasks/deploy.rake

## Server Configuration

### Web Server Root Path

Before deploying with Capistrano, you must update each of your web servers to point to the `current` directory inside of the configured `:deploy_to` directory. For example: `/var/www/html/current/pub` Refer to the [Capistrano Structure](http://capistranorb.com/documentation/getting-started/structure/) to learn more about Capistrano's folder structure.

## Magento Specific Tasks

All Magento 2 tasks used by the built-in `deploy.rake` file as well as some additional commands are implemented and exposed to the end-user for use directly via the cap tool. You can also see this list by running `cap -T` from your shell.

| cap command                           | what it does                                       |
| ------------------------------------- | -------------------------------------------------- |
| magento:cache:clean                   | Clean Magento cache by types                       |
| magento:cache:disable                 | Disable Magento cache                              |
| magento:cache:enable                  | Enable Magento cache                               |
| magento:cache:flush                   | Flush Magento cache storage                        |
| magento:cache:status                  | Check Magento cache enabled status                 |
| magento:cache:varnish:ban             | Add ban to Varnish for url(s)                      |
| magento:composer:install              | Run composer install                               |
| magento:deploy:mode:production        | Enables production mode                            |
| magento:deploy:mode:show              | Displays current application mode                  |
| magento:indexer:info                  | Shows allowed indexers                             |
| magento:indexer:reindex               | Reindex data by all indexers                       |
| magento:indexer:set-mode[mode,index]  | Sets mode of all indexers                          |
| magento:indexer:show-mode[index]      | Shows mode of all indexers                         |
| magento:indexer:status                | Shows status of all indexers                       |
| magento:maintenance:allow-ips[ip]     | Sets maintenance mode exempt IPs                   |
| magento:maintenance:disable           | Disable maintenance mode                           |
| magento:maintenance:enable            | Enable maintenance mode                            |
| magento:maintenance:status            | Displays maintenance mode status                   |
| magento:setup:di:compile              | Runs dependency injection compilation routine      |
| magento:setup:permissions             | Sets proper permissions on application             |
| magento:setup:static-content:deploy   | Deploys static view files                          |
| magento:setup:upgrade                 | Run the Magento upgrade process                    |

## Pending Changes Support

When the line `require 'capistrano/magento2/pending'` is included in your `Capfile` per the recommended configuration above, this gem will report changes pending deployment in an abbreviated git log style format. Here is an example:

```
00:00 deploy:pending:log
      01 git fetch origin
    ✔ 01 dalger@localhost 1.241s
    ✔ 01 dalger@localhost 1.259s
      Changes pending deployment on web1 (tags/2.1.2 -> 2.1):
      f511288 Thu Feb 23 12:19:20 2017 -0600 David Alger (HEAD -> 2.1, tag: 2.1.4, origin/2.1) Magento 2.1.4
      7fb219c Thu Feb 23 12:17:11 2017 -0600 David Alger (tag: 2.1.3) Magento 2.1.3
      570c9b3 Thu Feb 23 12:12:43 2017 -0600 David Alger Updated capistrano configuration
      No changes to deploy on web2 (from and to are the same: 2.1 -> 2.1)
```

When there are no changes due for deployment to any host, a warning requiring confirmation will be emitted by default:

```
No changes to deploy on web1 (from and to are the same: 2.1 -> 2.1)
No changes to deploy on web2 (from and to are the same: 2.1 -> 2.1)
Are you sure you want to continue? [y/n]
```

This confirmational warning can be disabled by including the following in your project's configuration:

```ruby
set :magento_deploy_pending_warn, false
```

### Pending Changes Configuration

| setting                          | what it does
| -------------------------------- | ------- | ---
| `:magento_deploy_pending_role`   | Role to check for pending changes on; defaults to `:all`
| `:magento_deploy_pending_warn`   | Set this to `false` to disable confirmational warning on zero-change deployments
| `:magento_deploy_pending_format` | Can be used to set a custom change log format; refer to `defaults.rb` for example

### Pending Changes Tasks

| cap command                           | what it does                                       |
| ------------------------------------- | -------------------------------------------------- |
| deploy:pending                        | Displays a summary of commits pending deployment   |

Note: For more details including screenshots of what this functionality does, reference [this post](https://github.com/davidalger/capistrano-magento2/issues/58#issuecomment-282404477).

## Terminal Notifier on OS X

This gem includes an optional configuration file include which adds notification support via the [terminal-notifier](https://rubygems.org/gems/terminal-notifier) gem. To configure notifications, simply add the following line to your `Capfile`:

```ruby
require 'capistrano/magento2/notifier'
```

**Notice:** The `terminal-notifier` gem is currently macOS specific and thus can not be used on generic *nix environments. Because this gem has been known to cause ruby stability issues on certain non-macOS environments, it is not specified as a hard requirement in this gem's gemspec. When using this functionality, it is expected the gem either be already present on your working environment or be added to your project's `Gemfile`:

```ruby
gem 'terminal-notifier'
```

## Development

After checking out the repo, run `bundle install` to install dependencies. Make the necessary changes, then run `bundle exec rake install` to install a modified version of the gem on your local system.

To release a new version, update the version number in `capistrano/magento2/version.rb`, merge all changes to master, and then run `bundle exec rake release`. This will create a git tag for the version (the tag will apply to the current HEAD), push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

_Note: Releasing a new version of the gem is only possible for those with maintainer access to the gem on rubygems.org._

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/davidalger/capistrano-magento2.

## License

This project is licensed under the Open Software License 3.0 (OSL-3.0). See included LICENSE file for full text of OSL-3.0.
