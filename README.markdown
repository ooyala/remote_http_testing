RemoteHttpTesting
=================

This module helps write integration tests which make HTTP requests to remote servers. Unlike Rack::Test, it doesn't make requests to an in-process Rack server.

Usage
=====
To use it, mix it in to your test case, specify the server your integration test is talking to, and begin
making requests.

    require "remote_http_testing"

    class MyServiceIntegrationTest < Scope::TestCase

      # This is the server all HTTP requests will be made to.
      def server()
        "http://localhost:8080"
      end

      setup_once do
        ensure_reachable!(server)
      end

      should "return a '401 Unauthorized' response when unaunthenticated" do
        get "/users/123/profile"
        assert_status 401
      end
    end

Reference
=========
These methods are available to your test.

    delete(url, params)

    get(url, params)

    patch(url, params)

    post(url, params)

    put(url, params)

    dom_response() - The response body parsed using Nokogiri::HTML().

    json_respones() - A hash of the response body, parsed using JSON.parse().

    assert_status(status_code, optional_helpful_message)

    ensure_reachable!(server_url, optional_server_display_name) - Exits if the given server is not reachable.

Development
===========
When working on this gem, after you've made changes, you can include your modified gem in any app using bundler by using :path in your Gemfile:

    gem "remote_http_testing", :path => "~/path/to/remote_http_testing"

Then run `bundle install` from within your app. The installed gem is now symlinked to your working copy.