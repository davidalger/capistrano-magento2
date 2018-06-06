##
 # Copyright © 2018 by David Alger. All rights reserved
 # 
 # Licensed under the Open Software License 3.0 (OSL-3.0)
 # See included LICENSE file for full text of OSL-3.0
 # 
 # http://davidalger.com/contact/
 ##

after "deploy:published", "cachetool:opcache:status"
after "deploy:published", "cachetool:opcache:reset"

namespace :cachetool do
 namespace :opcache do
   desc "Resets the contents of the php-opcode cache"
   task :reset do
     on release_roles :all do
       within release_path do
         execute :cachetool, 'opcache:reset'
       end
     end
   end

   desc "Show information about the php-opcode cache"
   task :status do
     # Due to nature of the output, run this in sequence vs in parallel (the default) with shortest possible wait time
     on release_roles(:all), in: :sequence, wait: 1 do
       within release_path do
         execute :cachetool, 'opcache:status'
       end
     end
   end
 end
end
