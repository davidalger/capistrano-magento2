##
 # Copyright © 2016 by David Alger. All rights reserved
 # 
 # Licensed under the Open Software License 3.0 (OSL-3.0)
 # See included LICENSE file for full text of OSL-3.0
 # 
 # http://davidalger.com/contact/
 ##

require "capistrano/pending/scm/base"

module Capistrano
  module Pending
    module SCM
      class Git < Base

        # Enhance the native deploy:pending:log command by updating repository and then showing the actual changes that will be deployed
        # Change the log output to oneline for easy reading
        # Params:
        # +from+ - commit-ish to compare from
        # +to+ - commit-ish to compare to
        # +returnOutput+ - whether to return or print the output
        def log(from, to, returnOutput=false)
          run_locally do
            # Ensure repository is up-to-date in order to give an accurate report of pending changes
            execute :git, :fetch, :origin

            # Since the :branch to deploy from may be behind the upstream branch, get name of upstream branch and use it for comparison.
            # We are using the test command in case the :branch is set to a specific commit hash, in which case there is no upstream branch.
            if test(:git, 'rev-parse', '--abbrev-ref', '--symbolic-full-name', to + '@{u}')
              # Compare against upstream branch, as local branch may be behind.
              to = capture(:git, 'rev-parse', '--abbrev-ref', '--symbolic-full-name',  to + '@{u}')
            end
            
            output = capture(:git, :log, "#{from}..#{to}", '--pretty="format:%C(yellow)%h %Cblue%>(12)%ad %Cgreen%<(7)%aN%Cred%d %Creset%s"')
            if returnOutput
              return output
            else 
              puts output
            end
          end
        end

      end
    end
  end
end

load File.expand_path('../../tasks/pending.rake', __FILE__)
