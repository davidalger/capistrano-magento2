# Capistrano::Magento2

[![Gem Version](https://badge.fury.io/rb/capistrano-magento2.svg)](https://badge.fury.io/rb/capistrano-magento2)

A Capistrano extension for Magento 2 deployments. Takes care of specific Magento 2 requirements and adds tasks specific to the Magento 2 application.

## Installation

### Standalone Installation

If you don't have an existing Ruby application you can install the gem using:

    $ gem install capistrano-magento2

### Add to Existing Ruby Application

Add this line to your application's Gemfile:

```ruby
gem 'capistrano-magento2'
```

And then execute:

    $ bundle

## Usage

Install Capistrano in your Magento project:

```shell
$ cd <project_root>
$ mkdir -p tools/cap
$ cd ./tools/cap
$ cap install
```

By default, Capistrano creates "staging" and "production" stages. If you want to define custom staging areas, you can do so using the "STAGES" option. e.g., `cap install STAGES=stage,prod .`

Update your project `Capfile` to look like the following:

```ruby
# Load DSL and set up stages
require 'capistrano/setup'

# Load Magento deployment tasks
require 'capistrano/magento2/deploy'
```

## Default Configuration

### Capistrano Built-Ins

For the sake of simplicity in new project setups `:linked_dirs` and `:linked_files` are pre-configured per the following.

```ruby
    set :linked_files, [
      'app/etc/env.php',
      'var/.setup_cronjob_status',
      'var/.update_cronjob_status',
      'sitemap.xml'
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

If you would like to customize the linked files or directories for your project, you can copy either/both of the above arrays into the `config/deploy.rb` or `config/deploy/*.rb` files and tweak them to fit your project's needs.

### Magento 2 Deploy Routine

A pre-built deploy routine is available out-of-the-box. This can be overriden on a per-project basis by including only the Magento 2 specific tasks and defining your own `deploy.rake` file under `lib/capistrano/tasks` in your projects capistrano install location.

To see what process the built-in routine runs, take a look at the included rake file here: https://github.com/davidalger/capistrano-magento2/blob/master/lib/capistrano/tasks/deploy.rake

## Magento Specific Tasks

All Magento 2 tasks used by the built-in `deploy.rake` file as well as some additional commands are implimented and exposed to the end-user for use directly via the cap tool. You can also see this list by running `cap -T` from your shell.

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

## Using Capistrano

For inrformation on how to use Capistrano and setup deployment take a look at the [Capistrano documentation](http://capistranorb.com) and [README](https://github.com/capistrano/capistrano/blob/master/README.md) file.

## Terminal Notifier on OS X
This gem specifies [terminal-notifier](https://rubygems.org/gems/terminal-notifier) as a dependency in order to support notifications on OS X via an optional include. To use the built-in notifications, add the following line to your `Capfile`:

```ruby
require 'capistrano/magento2/notifier'
```

## Development

After checking out the repo, run `bundle install` to install dependencies. Make the neccesary changes, then run `bundle exec rake install` to install a modified version of the gem on your local system.

To release a new version, update the version number in `capistrano/magento2/version.rb`, merge all changes to master, and then run `bundle exec rake release`. This will create a git tag for the version (the tag will apply to the current HEAD), push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

_Note: Releasing a new version of the gem is only possible for those with maintainer access to the gem on rubygems.org._

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/davidalger/capistrano-magento2.

## License

This project is licensed under the Open Software License 3.0 (OSL-3.0). See included LICENSE file for full text of OSL-3.0.
