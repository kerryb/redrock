require "redrock/server"

module RedRock
  def start port = 4242
    raise "RedRock is already running" if @server_thread
    @server_thread = Thread.new do
      Thin::Server.start('0.0.0.0', port) do
        run RedRock::Server.instance
      end
    end
  end

  def stop
    if @server_thread
      @server_thread.exit
      @server_thread = nil
    end
  end

  def method_missing name, *args, &block
    super unless Server.instance.respond_to? name
    start unless @server_thread
    Server.instance.send name, *args, &block
  end
end
