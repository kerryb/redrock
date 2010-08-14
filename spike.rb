require "thin"

class Server
  attr_accessor :reply

  def initialize reply
    @reply = reply
  end

  def call env
    [200, {"Content-Type" => "text/plain", "Content-Length" => (reply.length + 1).to_s}, "#{@reply}\n"]
  end
end

server = Server.new "hello"

web_server = Thread.new do
  Thin::Server.start('0.0.0.0', 3030) do
    run server
  end
end

sleep 5
server.reply = "goodbye"

web_server.join
