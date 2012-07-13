# -*- encoding: utf-8 -*-
#
# We created this project by running "bundle gem remote_http_testing".
#
$:.push File.expand_path("../lib", __FILE__)
require "remote_http_testing/version"

Gem::Specification.new do |s|
  s.name        = "remote_http_testing"
  s.version     = RemoteHttpTesting::VERSION
  s.authors     = ["Phil Crosby"]
  s.email       = ["phil.crosby@gmail.com"]
  s.homepage    = "http://github.com/ooyala/remote_http_testing"
  s.summary     = %q{A small library for making remote HTTP requests and response assertions in tests.}

  s.rubyforge_project = "remote_http_testing"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency 'rspec'
  s.add_development_dependency 'fakeweb'
  s.add_runtime_dependency "nokogiri"
  s.add_runtime_dependency "json"
end
