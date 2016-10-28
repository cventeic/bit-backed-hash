# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'bit_backed_hash/version'

Gem::Specification.new do |spec|
  spec.name          = "bit_backed_hash"
  spec.version       = Bit_Backed_Hash::VERSION
  spec.authors       = ["cventeic"]
  spec.email         = ["chris@venteicher.org"]
  spec.summary       = %q{Bit Backed Hash}
  spec.description   = %q{Bit Backed Hash}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "pry"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
end
