##
 # Copyright © 2016 by David Alger. All rights reserved
 # 
 # Licensed under the Open Software License 3.0 (OSL-3.0)
 # See included LICENSE file for full text of OSL-3.0
 # 
 # http://davidalger.com/contact/
 ##

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'capistrano/magento2/version'

Gem::Specification.new do |spec|
  spec.name          = 'capistrano-magento2'
  spec.version       = Capistrano::Magento2::VERSION
  spec.authors       = ['David Alger']
  spec.email         = ['davidmalger@gmail.com']

  spec.summary       = %q{A Capistrano extension for Magento 2 deployments.}
  spec.description   = %Q{#{spec.summary} Takes care of specific Magento 2 requirements and adds tasks specific to the Magento 2 application.}
  spec.homepage      = 'https://github.com/davidalger/capistrano-magento2'
  spec.license       = 'OSL-3.0'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'bin'
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'capistrano', '~> 3.1'

  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'rake', '~> 10.0'
end
