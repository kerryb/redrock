require "thin"
require "net/http"
require "json"
require "webmock"
require "webmock/rspec"

Thin::Logging.silent = true

module RedRock
  class Server
    include Singleton
    include WebMock
    include WebMock::Matchers

    def call env
      request = Rack::Request.new env
      http_method = request.request_method
      request_body = request.body.read
      request_headers = {}
      env.each do |k, v|
        request_headers[k.sub(/^HTTP_/, '')] = v if k =~ /^HTTP_|CONTENT_TYPE|CONTENT_LENGTH/
      end
      begin
        ::Net::HTTP.start(request_headers["HOST"]) do |http|
          request_class = ::Net::HTTP.const_get(http_method.capitalize)
          path = request.path_info
          path << "?#{request.query_string}" unless request.query_string.empty?
          request = request_class.new request.path_info, request_headers
          request.body = request_body unless request_body.empty?
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
end
