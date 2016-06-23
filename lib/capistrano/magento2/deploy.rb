##
 # Copyright © 2016 by David Alger. All rights reserved
 # 
 # Licensed under the Open Software License 3.0 (OSL-3.0)
 # See included LICENSE file for full text of OSL-3.0
 # 
 # http://davidalger.com/contact/
 ##

require 'capistrano/deploy'
# Explicitly load this file first so the pending commit message log shows before the production confirmation prompt
require 'capistrano/magento2/pending'
require 'capistrano/magento2'

load File.expand_path('../../tasks/deploy.rake', __FILE__)
