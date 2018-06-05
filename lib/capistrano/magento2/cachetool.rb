##
 # Copyright © 2018 by David Alger. All rights reserved
 # 
 # Licensed under the Open Software License 3.0 (OSL-3.0)
 # See included LICENSE file for full text of OSL-3.0
 # 
 # http://davidalger.com/contact/
 ##

require 'capistrano/deploy'

SSHKit.config.command_map[:cachetool] = "/usr/bin/env cachetool --"

load File.expand_path('../../tasks/cachetool.rake', __FILE__)
