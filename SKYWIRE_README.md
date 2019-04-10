Requires ruby 2.5+

## Installation

Install bundler and this package 

    $ sudo gem install bundler
    $ cd <project_root>
    $ echo -e "source 'https://rubygems.org'\ngem 'capistrano-magento2', :git => 'git@github.com:Skywire/capistrano-magento2.git', :branch => 'skywire-master'" > Gemfile
    $ bundle install
    $ mkdir -p tools/cap
    $ cd ./tools/cap
    $ cap install

### Configure Capfile (global settings)

Replace `tools/cap/Capfile.rb` with

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


### Configure Capistrano

Refer to the configuration sestion in the main README.md doc titled `Capistrano Configuration`
You may also need to update `config/deploy.rb` with the following on Sonassi servers:
~~~
set :default_env, { path: '/opt/php/php-7.2/bin/:/microcloud/domains/cordm2/domains/.composer:$PATH' }
~~~
You can also set the patternlab directory with:
~~~
set :patternlab_paths, ["skywire-patternlab"]
~~~

### Configure production stage

Update `tools/cap/config/deploy/production.rb`, Sonassi example provided

    server "magestack", user: "www-data", roles: %w{app db web}, my_property: :my_value
    set :deploy_to, '/microcloud/domains/cordev/domains/s4.corneyandbarrow.com/capistrano/'
    set :db_backup_path, '/microcloud/domains/cordev/domains/s4.corneyandbarrow.com/capistrano/backup'
    set :branch, $1 if `git branch` =~ /\* (\S+)\s/m

All required paths will be created automatically on the first deployment

`:db_backup_path` is optional but advised as it will allow DB rollbacks

#### Configure additional stages

Add additional files to `tools/cap/config/deploy/` as required, e.g. `s1.rb`

Each file contains a specific server and environment configuration

## Server configuration

You will need to replace your server's web root directory with a symlink to `capistrano/current`

## Relative Symlinks

If the server you are using requires relative symlinks e.g. Sonassi Magestack then you will need an additional task file

Create file `tools/cap/lib/capistrano/tasks/relative_symlinks.rake` with these contents

    ## Use relative path instead of absolute

    Rake::Task["deploy:symlink:linked_dirs"].clear_actions
    Rake::Task["deploy:symlink:linked_files"].clear_actions
    Rake::Task["deploy:symlink:release"].clear_actions

    namespace :deploy do
    namespace :symlink do
        desc 'Symlink release to current'
        task :release do
        on release_roles :all do
            tmp_current_path = release_path.parent.join(current_path.basename)
            execute :ln, '-s', release_path.relative_path_from(current_path.dirname), tmp_current_path
            execute :mv, tmp_current_path, current_path.parent
        end
        end

        desc 'Symlink files and directories from shared to release'
        task :shared do
        invoke 'deploy:symlink:linked_files'
        invoke 'deploy:symlink:linked_dirs'
        end

        desc 'Symlink linked directories'
        task :linked_dirs do
        next unless any? :linked_dirs
        on release_roles :all do
            execute :mkdir, '-p', linked_dir_parents(release_path)

            fetch(:linked_dirs).each do |dir|
            target = release_path.join(dir)
            source = shared_path.join(dir)
            unless test "[ -L #{target} ]"
                if test "[ -d #{target} ]"
                execute :rm, '-rf', target
                end
                execute :ln, '-s', source.relative_path_from(target.dirname), target
            end
            end
        end
        end

        desc 'Symlink linked files'
        task :linked_files do
        next unless any? :linked_files
        on release_roles :all do
            execute :mkdir, '-p', linked_file_dirs(release_path)

            fetch(:linked_files).each do |file|
            target = release_path.join(file)
            source = shared_path.join(file)
            unless test "[ -L #{target} ]"
                if test "[ -f #{target} ]"
                execute :rm, target
                end
                execute :ln, '-s', source.relative_path_from(target.dirname), target
            end
            end
        end
        end
    end
    end

## Run a deployment

`cap [stage] deploy`

e.g. `cap production deploy`

## Rollback a deployment

`cap [stage] deploy:rollback`

e.g. `cap production deploy:rollback`

see https://capistranorb.com/documentation/getting-started/rollbacks/ for information on rollbacks
