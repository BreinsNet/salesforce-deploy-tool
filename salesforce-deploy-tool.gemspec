# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'salesforcedeploytool/version'

Gem::Specification.new do |spec|
  spec.name          = "salesforce-deploy-tool"
  spec.version       = SalesforceDeployTool::VERSION
  spec.authors       = ["Juan Breinlinger"]
  spec.email         = ["<juan.brein@breins.net>"]
  spec.summary       = %q{A tool to help you at deploying and pulling code and metadata from salesforce}
  spec.description   = %q{}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
end
