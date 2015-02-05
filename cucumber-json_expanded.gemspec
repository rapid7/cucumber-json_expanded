# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cucumber/json_expanded/version'

Gem::Specification.new do |spec|
  spec.name          = "cucumber-json_expanded"
  spec.version       = Cucumber::JsonExpanded::VERSION
  spec.authors       = ["Brandon Turner","Lance Sanchez"]
  spec.email         = ["Brandon_Turner@rapid7.com", "lance_sanchez@rapid7.com"]
  spec.summary       = %q{Fixing cucumber json format for scenario outlines}
  spec.description   = %q{Creating this gem so we have consistent output from cucumber.}
  spec.homepage      = "https://github.com/rapid7/cucumber-json_expanded"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency 'metasploit-version', '= 0.1.3.pre.changelog.pre.template'
  
  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'cucumber', '~> 1.3.14'
  spec.add_development_dependency 'aruba'
end
