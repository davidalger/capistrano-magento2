# Capistrano::Magento2

[![Gem Version](https://badge.fury.io/rb/capistrano-magento2.svg)](https://badge.fury.io/rb/capistrano-magento2)

A Capistrano extension for Magento 2 deployments. Takes care of specific Magento 2 requirements and adds tasks specific to the Magento 2 application.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'capistrano-magento2'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install capistrano-magento2

## Usage

Install Capistrano in your Magento project:

    $ cd <project_root>
    $ mkdir -p tools/cap
    $ cd ./tools/cap
    $ cap install

Update your project `Capfile` to look like the following:

```ruby
# Load DSL and set up stages
require 'capistrano/setup'

# Load Magento deployment tasks
require 'capistrano/magento'
```

This gem requires [terminal-notifier](https://rubygems.org/gems/terminal-notifier) and adds notifications to the deployment process via an optional include. To use terminal-notifier, add the following line to your `Capfile`:

```ruby
require 'capistrano/magento2/deploy/notify'
```

## Development

After checking out the repo, run `bundle install` to install dependencies.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `capistrano/magento2/version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/davidalger/capistrano-magento2.

## License

This project is licensed under the Open Software License 3.0 (OSL-3.0). See included LICENSE file for full text of OSL-3.0.
