#!/usr/bin/env ruby -rubygems
# -*- encoding: utf-8 -*-

Gem::Specification.new do |gem|
  gem.version = File.read('VERSION').chomp
  gem.date = File.mtime('VERSION').strftime('%Y-%m-%d')

  gem.name = 'sasquatch'
  gem.homepage = 'http://github.com/rsinger/sasquatch'
  gem.license = 'MIT' if gem.respond_to?(:license=)
  gem.summary = 'A highly opinionated Ruby client for the Talis Platform.'
  gem.description = 'A highly opinionated Ruby client for the Talis Platform using HTTParty and RDF.rb'

  gem.authors = ['Ross Singer']
  gem.email = 'ross.singer@talis.com'

  gem.platform = Gem::Platform::RUBY
  gem.files = %w(README VERSION) + Dir.glob('lib/**/*.rb')
  gem.require_paths = %w(lib)
  gem.extensions = %w()
  gem.test_files = %w()
  gem.has_rdoc = false

  gem.required_ruby_version = '>= 1.8.7'
  gem.requirements = []
  gem.add_runtime_dependency 'httparty', '>= 0.7.4'
  gem.add_runtime_dependency 'rdf', '>= 0.3.1'
  gem.add_runtime_dependency 'rdf/json', '>= 0.3.0'
  gem.add_runtime_dependency 'sparql-client', '>= 0.0.9'
  gem.add_development_dependency 'rspec', '>= 2.1.0'
  gem.post_install_message = nil
end