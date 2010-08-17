require "redrock/server"

module RedRock
  def start
    @server_thread = Thread.new do
      Thin::Server.start('0.0.0.0', 4242) do
        run RedRock::Server.instance
      end
    end
  end

  def stop
    @server_thread.exit
  end

  def method_missing name, *args, &block
    super unless Server.instance.respond_to? name
    start unless @server_thread
    Server.instance.send name, *args, &block
  end
end
