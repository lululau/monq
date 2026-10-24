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
      ensure_ssh_proxy!
      opts = Config.client_options(client_config)
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

      @ssh_proxy&.reconnect!
      @client&.close
      connect!
    end

    def namespace_module
      @namespace_module ||= Object.const_set(namespace, Module.new)
    end

    def sandbox?
      !@sandbox_session.nil?
    end

    def load_models!
      install_namespace_api!
      path = File.join(@model_dir, "#{Config.prefix_for(name)}.rb")
      unless File.file?(path)
        warn "model file not found: #{path}"
        return
      end

      namespace_module.module_eval(File.read(path), path)
      bind_clients!
      track_embedded_classes!
      install_abbreviations!
    end

    def models
      namespace_module.constants.filter_map do |const_name|
        klass = namespace_module.const_get(const_name)
        next unless klass.is_a?(Class) && klass < Mongoid::Document && !klass.embedded?
        next unless klass.name.to_s.split("::").last == const_name.to_s

        klass
      end
    end

    def redefine!
      raise Error, "sandbox is active; run sandbox-quit first" if sandbox?

      tracked_classes.each do |klass|
        Mongoid.models.delete(klass) if Mongoid.models.respond_to?(:delete)
      end
      tracked_names.each { |n| namespace_module.send(:remove_const, n) if namespace_module.const_defined?(n, false) }
      @tracked = []
      load_models!
    end

    private

    def ensure_ssh_proxy!
      return unless config[:ssh]
      return if @ssh_proxy

      target = Config.ssh_forward_target(config)
      ssh = config[:ssh]
      @ssh_proxy = SSHProxy.new(
        host: ssh[:host],
        user: ssh[:user],
        password: ssh[:password],
        port: ssh[:port] || 22,
        forward_host: target[:host],
        forward_port: target[:port],
        local_port: ssh[:local_port]
      )
    end

    def client_config
      return config unless @ssh_proxy

      config.merge(ssh: config[:ssh].merge(local_port: @ssh_proxy.local_port, local_host: "127.0.0.1"))
    end

    def tracked_names
      @tracked ||= []
    end

    def tracked_classes
      tracked_names.filter_map do |n|
        namespace_module.const_get(n) if namespace_module.const_defined?(n, false)
      end.select { |k| k.is_a?(Class) }
    end

    def bind_clients!
      namespace_module.constants.each do |const_name|
        klass = namespace_module.const_get(const_name)
        next unless klass.is_a?(Class) && klass < Mongoid::Document
        next if klass.embedded?

        current = klass.storage_options[:client] || klass.storage_options["client"]
        next if current && current.to_sym != :default

        klass.store_in klass.storage_options.merge(client: client_name)
        tracked_names << const_name
      end
    end

    def track_embedded_classes!
      models.each do |klass|
        relations = klass.embedded_relations
        relations = klass.relations if relations.nil? || (relations.respond_to?(:empty?) && relations.empty? && klass.respond_to?(:relations))
        Array(relations).each do |entry|
          relation = entry.is_a?(Array) ? entry.last : entry
          class_name = relation.respond_to?(:class_name) ? relation.class_name : relation[:class_name]
          next if class_name.nil? || class_name.to_s.empty?

          embedded = namespace_module.const_get(class_name) rescue nil
          next unless embedded.is_a?(Class) && embedded < Mongoid::Document
          next unless embedded.name.to_s.start_with?("#{namespace}::")

          short = embedded.name.split("::").last.to_sym
          tracked_names << short unless tracked_names.include?(short)
        end
      end
    end

    def install_abbreviations!
      models.each do |klass|
        abbr = klass.name.split("::").last.gsub(/[^A-Z]/, "")
        abbr = "M" if abbr.empty?
        candidate = abbr
        n = 2
        while namespace_module.const_defined?(candidate, false)
          candidate = "#{abbr}#{n}"
          n += 1
        end
        namespace_module.const_set(candidate, klass)
        tracked_names << candidate.to_sym
      end
    end

    def install_namespace_api!
      env = self
      mod = namespace_module
      mod.define_singleton_method(:client) { env.client }
      mod.define_singleton_method(:models) { env.models }
      mod.define_singleton_method(:collections) { env.client.database.collection_names }
      mod.define_singleton_method(:config) { env.config }
      mod.define_singleton_method(:q) { |doc| env.client.database.command(doc) }
    end
  end
end
