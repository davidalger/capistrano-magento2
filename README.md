# Capistrano::Magento2

[![Gem Version](https://badge.fury.io/rb/capistrano-magento2.svg)](https://badge.fury.io/rb/capistrano-magento2)

A Capistrano extension for Magento 2 deployments. Takes care of specific Magento 2 requirements and adds tasks specific to the Magento 2 application.

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

| setting                       | default | what it does
| ----------------------------- | ------- | ---
| `:magento_deploy_languages`   | `['en_US']` | Array of languages passed to static content deploy routine
| `:magento_deploy_themes`      | `[]`   | Array of themes passed to static content deploy routine (Magento 2.1+ only)
| `:magento_deploy_composer`    | `true` | Enables composer install behaviour in the built-in deploy routine
| `:magento_deploy_production`  | `true` | Enables production specific DI compilation and static content generation
| `:magento_deploy_maintenance` | `true` | Enables use of maintenance mode while magento:setup:upgrade runs
| `:magento_deploy_confirm`     | `[]`   | Used to require confirmation of deployment to a set of capistrano stages
| `:magento_deploy_chmod_d`     | `2770` | Default permissions applied to all directories in the release path
| `:magento_deploy_chmod_f`     | `0660` | Default permissions applied to all non-executable files in the release path
| `:magento_deploy_chmod_x`     | `['bin/magento']` | Default list of files in release path to set executable bit on

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
  'var/.setup_cronjob_status',
  'var/.update_cronjob_status',
  'pub/sitemap.xml'
]

set :linked_dirs, [
  'pub/media', 
  'var/backups', 
  'var/composer_home', 
  'var/importexport', 
  'var/import_history', 
  'var/log',
  'var/session', 
  'var/tmp'
]
```

If you would like to customize the linked files or directories for your project, you can copy either one or both of the above arrays into the `config/deploy.rb` or `config/deploy/*.rb` files and tweak them to fit your project's needs.

### Magento 2 Deploy Routine

A pre-built deploy routine is available out-of-the-box. This can be overriden on a per-project basis by including only the Magento 2 specific tasks and defining your own `deploy.rake` file under `lib/capistrano/tasks` in your projects Capistrano install location.

To see what process the built-in routine runs, take a look at the included rake file here: https://github.com/davidalger/capistrano-magento2/blob/master/lib/capistrano/tasks/deploy.rake

## Server Configuration

### Web Server Root Path

Before deploying with Capistrano, you must update each of your web servers to point to a `current` directory inside of the `:deploy_to` directory. For example: `/var/www/html/current` Refer to the [Capistrano Structure](http://capistranorb.com/documentation/getting-started/structure/) to learn more about Capistrano's folder structure.

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

## Terminal Notifier on OS X
This gem specifies [terminal-notifier](https://rubygems.org/gems/terminal-notifier) as a dependency in order to support notifications on OS X via an optional include. To use the built-in notifications, add the following line to your `Capfile`:

```ruby
require 'capistrano/magento2/notifier'
```

## Pending Changes

This gem specifies [capistrano-pending](https://rubygems.org/gems/capistrano-pending) as a dependency and adds some (optional) custom functionality on top of that gem: Any time the `deploy` command is run, a one line summary of git commits that will be deployed will be displayed. If the server(s) you are deploying to already have the latest changes, you will be warned of this and a prompt will appear confirming that you want to continue deploying.

To add the `capistrano-pending` gem and additional functionality to you project, add the following line to your `Capfile`:

```ruby
require 'capistrano/magento2/pending'
```

## Development

After checking out the repo, run `bundle install` to install dependencies. Make the necessary changes, then run `bundle exec rake install` to install a modified version of the gem on your local system.

To release a new version, update the version number in `capistrano/magento2/version.rb`, merge all changes to master, and then run `bundle exec rake release`. This will create a git tag for the version (the tag will apply to the current HEAD), push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

_Note: Releasing a new version of the gem is only possible for those with maintainer access to the gem on rubygems.org._

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/davidalger/capistrano-magento2.

## License

This project is licensed under the Open Software License 3.0 (OSL-3.0). See included LICENSE file for full text of OSL-3.0.
