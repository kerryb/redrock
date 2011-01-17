class TestRequest
  def self.get url
    new :get, url
  end

  def self.post url, body
    new :post, url, body
  end

  def initialize method, url, body = nil, headers = {}
    @method = method
    @url = url
    @request_body = body
    @headers = headers
  end

  def get
    Curl::Easy.http_get @url do |request|
      setup_request request
    end
  end

  def post
    Curl::Easy.http_post @url, @request_body do |request|
      setup_request request
    end
  end

  def setup_request request
    setup_headers request
    setup_basic_auth request
  end
  private :setup_request

  def setup_headers request
    @headers.each do |key, value|
      request.headers[key] = value
    end
  end
  private :setup_headers

  def setup_basic_auth request
    return unless @username
    request.http_auth_types = :basic
    request.username = @username
    request.password = @password
  end
  private :setup_basic_auth

  def response
    @response ||= send @method
  end
  private :response

  def with_headers headers
    @headers = headers
    self
  end

  def with_basic_auth username, password
    @username = username
    @password = password
    self
  end

  def execute
    response
    nil
  end

  def response_code
    response.response_code
  end

  def body
    response.body_str
  end

  def headers
    @response_headers ||= Hash[*(response.header_str.grep(/:/).map {|l| l.strip.split /:\s*/ }.flatten)]
  end
end
