require 'rubygems'
require 'rake/gempackagetask'

PLUGIN = "merb_async_observer"
NAME = "merb_async_observer"
VERSION = "0.0.4"
AUTHORS = ["Keith Rarick", "Chris Van Pelt"]
EMAIL = "vanpelt@doloreslabs.com"
HOMEPAGE = "http://whatididlastnight.com"
SUMMARY = "A kickass merb binding to beanstalkd"

spec = Gem::Specification.new do |s|
  s.name = NAME
  s.version = VERSION
  s.platform = Gem::Platform::RUBY
  s.has_rdoc = true
  s.summary = SUMMARY
  s.description = s.summary
  s.authors = AUTHORS
  s.email = EMAIL
  s.homepage = HOMEPAGE
  s.add_dependency('merb-core', '>= 0.9.0')
  s.add_dependency('activerecord', '>= 2.1.0')
  #s.add_dependency('facebooker')
  s.require_path = 'lib'
  s.autorequire = PLUGIN
  s.files = %w(COPYING README Rakefile) + Dir.glob("{lib,generators}/**/*")
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.gem_spec = spec
end

task :install => [:package] do
  sh %{sudo gem install pkg/#{NAME}-#{VERSION}}
end
