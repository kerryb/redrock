require "thin"
require "net/http"
require "webmock"


module RedRock
  class Server
    include WebMock
    include Singleton

    def call env
      request = Rack::Request.new env
      http_method = request.request_method
      request_headers = {}
      env.each do |k, v|
        request_headers[k.sub(/^HTTP_/, '')] = v if k =~ /^HTTP_/
      end
      begin
        ::Net::HTTP.start(request_headers["HOST"]) do |http|
          request_class = ::Net::HTTP.const_get(http_method.capitalize)
          request = request_class.new request.path_info, request_headers
          @response = http.request request
        end
      rescue WebMock::NetConnectNotAllowedError => e
        return [500,
          {"Content-Type" => "text/plain", "Content-Length" => e.message.length.to_s},
          e.message]
      end
      response_headers = {}
      @response.to_hash.each {|k,v| response_headers[k] = v.join "\n"}
      response_headers.delete "status"
      [@response.code, response_headers, @response.body]
    end
  end

  def start
    web_server = Thread.new do
      Thin::Server.start('0.0.0.0', 3030) do
        run RedRock::Server.instance
      end
    end
    web_server.join
  end

  def method_missing name, *args, &block
    super unless Server.instance.respond_to? name
    Server.instance.send name, *args, &block
  end
end

include RedRock

stub_request :any, "localhost:3030/foo"
Server.start
