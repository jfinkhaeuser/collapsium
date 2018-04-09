# coding: utf-8
#
# collapsium
# https://github.com/jfinkhaeuser/collapsium
#
# Copyright (c) 2016-2017 Jens Finkhaeuser and other collapsium contributors.
# All rights reserved.
#

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'collapsium/version'

# rubocop:disable Style/UnneededPercentQ
# rubocop:disable Layout/SpaceAroundOperators
Gem::Specification.new do |spec|
  spec.name          = "collapsium"
  spec.version       = Collapsium::VERSION
  spec.authors       = ["Jens Finkhaeuser"]
  spec.email         = ["jens@finkhaeuser.de"]
  spec.description   = %q(
    Provides IndifferentAccess, RecursiveMerge, PathedAccess, etc.
  )
  spec.summary       = %q(
    Provides various Hash extensions, and an UberHash class that uses them all.
  )
  spec.homepage      = "https://github.com/jfinkhaeuser/collapsium"
  spec.license       = "MITNFA"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '>= 2.0'

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 11.3"
  spec.add_development_dependency "rspec", "~> 3.7"
  spec.add_development_dependency "simplecov", "~> 0.16"
  spec.add_development_dependency "yard", "~> 0.9", ">= 0.9.12"
end
# rubocop:enable Layout/SpaceAroundOperators
# rubocop:enable Style/UnneededPercentQ
