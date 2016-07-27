##
 # Copyright © 2016 by David Alger. All rights reserved
 # 
 # Licensed under the Open Software License 3.0 (OSL-3.0)
 # See included LICENSE file for full text of OSL-3.0
 # 
 # http://davidalger.com/contact/
 ##

require 'terminal-notifier'

namespace :deploy do
  after 'deploy:failed', :notify_user_failure do
    run_locally do
      set :message, "ERROR in deploying " + fetch(:application).to_s + " to " + fetch(:stage).to_s
      TerminalNotifier.notify(fetch(:message), :title => 'Capistrano')
    end
  end

  after :finished, :notify_user do
    run_locally do
      set :message, "Finished deploying " + fetch(:application).to_s + " to " + fetch(:stage).to_s
      TerminalNotifier.notify(fetch(:message), :title => 'Capistrano')
    end
  end
end
