# frozen_string_literal: true

require "net/ssh/gateway"

module Monq
  class SSHProxy
    attr_reader :local_port

    def initialize(host:, user:, forward_host:, forward_port:, port: 22, password: nil, local_port: nil)
      @host = host
      @user = user
      @forward_host = forward_host
      @forward_port = forward_port
      @opts = { port: port }
      @opts[:password] = password if password
      open_gateway!(local_port)
    end

    def database_host_port
      { host: "127.0.0.1", port: @local_port }
    end

    def active?
      @gateway.active?
    end

    def reconnect
      reconnect! unless active?
    end

    def reconnect!
      @gateway.shutdown!
      open_gateway!(@local_port)
    end

    private

    def open_gateway!(local_port)
      @gateway = Net::SSH::Gateway.new(@host, @user, @opts)
      @local_port = @gateway.open(@forward_host, @forward_port, local_port)
    end
  end
end
