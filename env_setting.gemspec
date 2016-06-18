# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'env_setting/version'

Gem::Specification.new do |spec|
  spec.name          = "env_setting"
  spec.version       = EnvSetting::VERSION
  spec.authors       = ["Will Spurgin"]
  spec.email         = ["will.spurgin@orm-tech.com"]
  spec.summary       = %q{Mange your environment variables in OOP style}
  spec.description   = %q{Allows OOP access to ENV variables by a slight re-write of the env_bang gem.}
  spec.homepage      = "https://github.com/ormtech/env_setting"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "~> 3.4"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "coveralls"
end
