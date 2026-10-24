# frozen_string_literal: true

require "mongoid"

module Monq
  class Environment
    attr_reader :name, :config, :client_name, :namespace, :client, :ssh_proxy

    def initialize(name, config, first:, model_dir:)
      @name = name
      @config = config
      @first = first
      @model_dir = model_dir
      @client_name = Config.client_name_for(name)
      @namespace = config[:namespace]
      @models = []
      @sandbox_session = nil
    end

    def connect!
      opts = Config.client_options(config)
      @client = Mongo::Client.new(opts[:hosts], **opts[:options].merge(database: opts[:database]))
      Mongoid::Clients.set(client_name, @client)
      Mongoid::Clients.set(:default, @client) if @first
      hello!
    end

    def hello!
      @client.database.command(hello: 1).documents.first
    end

    def ping?
      hello!
      true
    rescue StandardError
      false
    end

    def reconnect!
      raise Error, "sandbox is active; run sandbox-quit first" if sandbox?

      @client&.close
      connect!
    end

    def namespace_module
      @namespace_module ||= Object.const_set(namespace, Module.new)
    end

    def sandbox?
      !@sandbox_session.nil?
    end
  end
end
