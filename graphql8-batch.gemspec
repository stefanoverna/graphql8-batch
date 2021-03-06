# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'graphql8/batch/version'

Gem::Specification.new do |spec|
  spec.name          = "graphql8-batch"
  spec.version       = GraphQL8::Batch::VERSION
  spec.authors       = ["Dylan Thacker-Smith"]
  spec.email         = ["gems@shopify.com"]

  spec.summary       = "A query batching executor for the graphql gem"
  spec.homepage      = "https://github.com/Shopify/graphql8-batch"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "graphql8", ">= 1.3", "< 2"
  spec.add_runtime_dependency "promise.rb", "~> 0.7.2"

  spec.add_development_dependency "byebug" if RUBY_ENGINE == 'ruby'
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest"
end
