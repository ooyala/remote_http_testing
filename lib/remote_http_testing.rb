require "remote_http_testing/version"
require "cgi"
require "nokogiri"
require "json"
require "net/http"
require "rack/mock"

#
# This module helps write integration tests which make HTTP requests to remote servers. Unlike Rack::Test,
# it doesn't make requests to an in-process Rack server. Include it into your test case class.
#
# This module's API should match the API of Rack::Test. In the future, we should consider whether it's just as
# easy to amend Rack::Test so that it can make requests to remote servers, since Rack::Test has supoprt for
# other desirable features.
#
module RemoteHttpTesting
  attr_accessor :last_response
  attr_accessor :last_request
  # You can set this to be a Hash, and these HTTP headers will be added to all requests.
  attr_accessor :headers_for_request

  # Define this method to return the URL of the HTTP server to talk to, e.g. "http://localhost:3000"
  def server() raise "You need to define a server() method." end

  def dom_response
    @dom_response ||= Nokogiri::HTML(last_response.body)
  end

  def json_response
    @json_response ||= JSON.parse(last_response.body)
  end

  # Temporarily make requests to a different server than the one specified by your server() method.
  def use_server(server, &block)
    @temporary_server = server
    begin
      yield
    ensure
      @temporary_server = nil
    end
  end

  def current_server() (@temporary_server || self.server) end

  # Prints out an error message and exits the program (to avoid running subsequent tests which are just
  # going to fail) if the server is not reachable.
  def ensure_reachable!(server_url, server_display_name = nil)
    unless server_reachable?(server_url)
      failure_message = server_display_name ? "#{server_display_name} at #{server_url}" : server_url
      puts "FAIL: Unable to connect to #{failure_message}"
      exit 1
    end
  end

  # True if the server is reachable. Fails if the server can't be contacted within 2 seconds.
  def server_reachable?(server_url)
    uri = URI.parse(server_url)
    request = Net::HTTP.new(uri.host, uri.port)
    request.read_timeout = 2
    response = nil
    begin
      response = request.request(create_request(server_url, :get))
    rescue StandardError, Timeout::Error
    end
    !response.nil? && response.code.to_i == 200
  end

  def delete(url, params = {}, request_body = nil) perform_request(url, :delete, params, request_body) end
  def get(url, params = {}, request_body = nil) perform_request(url, :get, params, request_body) end

  # POST/PUT/PATCH should params should typically be form encoded and present
  # in the request body. This ensures the format remains consistent with
  # Rack Test (ie - get {params}, {session info})
  def post( url, form_params = {}, params = {}) perform_request(url, :post,  params, URI.encode_www_form(form_params)) end
  def put(  url, form_params = {}, params = {}) perform_request(url, :put,   params, URI.encode_www_form(form_params)) end
  def patch(url, form_params = {}, params = {}) perform_request(url, :patch, params, URI.encode_www_form(form_params)) end

  # Used by perform_request. This can be overridden by integration tests to append things to the request,
  # like adding a login cookie.
  def create_request(url, http_method, params = {}, request_body = nil)
    uri = URI.parse(url)
    RemoteHttpTesting::populate_uri_with_querystring(uri, params)
    request_class = case http_method
      when :delete then Net::HTTP::Delete
      when :get then Net::HTTP::Get
      when :post then Net::HTTP::Post
      when :put then Net::HTTP::Put
      when :patch then Net::HTTP::Patch
    end
    request = request_class.new(uri.request_uri)
    request.body = request_body if request_body
    headers_for_request.each { |key, value| request.add_field(key, value) } if headers_for_request
    request
  end

  def perform_request(url, http_method, params = {}, request_body = nil)
    # Reset last request
    self.last_response = @dom_response = @json_response = nil

    url = current_server + url
    self.last_request = create_request(url, http_method, params, request_body)

    response = fetch(url, self.last_request)

    self.last_response = wrap_with_mock(response)
  end

  def fetch(url, request)
    uri = URI.parse(url)
    begin
      response = Net::HTTP.new(uri.host, uri.port).request(request)

      # Follow redirects
      redirect_limit = 10
      while response.header['location']
        raise "Recursive redirect: #{response.header['location']}" if redirect_limit <= 0
        prev_redirect = response.header['location']
        response = Net::HTTP.get_response(URI.parse(response.header['location']))
        redirect_limit -= 1
      end
    rescue Errno::ECONNREFUSED => error
      raise "Unable to connect to #{self.current_server}"
    end
    response
  end

  def self.populate_uri_with_querystring(uri, query_string_hash)
    return if query_string_hash.nil? || query_string_hash == ""
    key_values = query_string_hash.map { |key, value| "#{key}=#{CGI.escape(value.to_s)}" }.join("&")
    uri.query = uri.query.to_s.empty? ? key_values : "&" + key_values # uri.query can be nil
  end

  def assert_status(status_code, helpful_message = last_response.body)
    assert_equal(status_code.to_i, last_response.code.to_i, helpful_message)
  end

  def assert_content_include?(string)
    assert_block("Failed: content did not include the string: #{string}") { content_include?(string) }
  end

  def assert_content_not_include?(string)
    assert_block("Failed: content should not have included this string but it did: #{string}") do
      !content_include?(string)
    end
  end

  def content_include?(string)
    raise "No request was made yet, or no response was returned" unless last_response
    last_response.body.include?(string)
  end

  # This is intended to provide similar functionality to the Rails assert_select helper.
  # With no additional options, "assert_select('my_selector')" just ensures there's an element matching the
  # given selector, assuming the response is structured like XML.
  def assert_select(css_selector, options = {})
    raise "You're trying to assert_select when there hasn't been a response yet." unless dom_response
    assert_block("There were no elements matching #{css_selector}") do
      !dom_response.css(css_selector).empty?
    end
  end

  def wrap_with_mock(response)
    Rack::MockResponse.new(response.code, response.header.to_hash, response.body)
  end
end
