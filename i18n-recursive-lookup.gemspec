# encoding: utf-8

$:.unshift File.expand_path('../lib', __FILE__)
require 'i18n-recursive-lookup/version'

Gem::Specification.new do |s|
  s.name          = "i18n-recursive-lookup"
  s.version       = I18n::RecursiveLookup::VERSION
  s.authors       = ["Octavian Neamtu"]
  s.email         = ["oneamtu89@gmail.com"]
  s.homepage      = "https://github.com//i18n-recursive-lookup"
  s.summary       = "Provides a backend to the i18n gem to allow translation definitions to reference other definitions"
  s.description   = "Provides a backend to the i18n gem to allow a definition to contain embedded references to other definitions by introducing the special embedded notation ${}. E.g. {foo: 'bar', baz: ${foo}} will evaluate t(:baz) to 'bar'."

  s.files         = `git ls-files app lib`.split("\n")
  s.platform      = Gem::Platform::RUBY
  s.require_paths = ['lib']
  s.rubyforge_project = '[none]'

  s.add_runtime_dependency 'i18n'
  s.add_development_dependency 'mocha'
  s.add_development_dependency 'test_declarative'
end
