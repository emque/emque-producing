# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'emque_messages/version'

Gem::Specification.new do |spec|
  spec.name          = "emquemessages"
  spec.version       = Emque::Messages::VERSION
  spec.authors       = ["Emily Dobervich", "Ryan Williams"]
  spec.email         = ["emily@teamsnap.com", "ryan.williams@teamsnap.com"]
  spec.summary       = %q{A gem for producing emque messages to Kafka}
  spec.description   = %q{}
  spec.homepage      = ""
  spec.license       = ""
  spec.required_ruby_version = '>= 1.9.3'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "poseidon", "> 0.0.4"
  spec.add_dependency "activesupport", "~> 3.2", ">= 3.2.18"
  spec.add_dependency "virtus"

  spec.add_development_dependency "bundler", "~> 1.0"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "pry"
end
