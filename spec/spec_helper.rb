require File.expand_path('../../lib/remote_http_testing', __FILE__)
require 'fakeweb'

FakeWeb.register_uri :get,
                     'http://example.com/index.html',
                     :response => File.read('spec/fakeweb/example.com.html')
FakeWeb.register_uri :get,
                     'http://example.com/index.json',
                     :response => File.read('spec/fakeweb/example.com.json')
