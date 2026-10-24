# frozen_string_literal: true

require "yaml"
require "ostruct"

module Monq
  module Config
    RESERVED = %w[default arql].freeze

    module_function

    def load_file(path)
      raw = YAML.safe_load(File.read(path), aliases: true)
      (raw || {}).transform_keys(&:to_s)
    rescue ArgumentError
      raw = YAML.safe_load(File.read(path))
      (raw || {}).transform_keys(&:to_s)
    end

    def select_environments(yaml, names, options)
      yaml = stringify(yaml)
      if names.nil? || names.empty?
        return { "default" => cli_env(options) } if sufficient_cli?(options)

        raise Error, "No -e given and CLI has no connection. Pass -e or --uri, or create ~/.monq.d/init.yml"
      end

      names.each do |name|
        raise Error, "#{name} is a reserved environment name" if RESERVED.include?(name)
        raise Error, "Environment #{name} not in config. Known: #{known(yaml).join(', ')}" unless yaml.key?(name)
      end

      selected = names.to_h { |n| [n, deep_sym(yaml[n])] }
      apply_cli!(selected, options)
      assign_namespaces!(selected)
      assert_unique_namespaces!(selected)
      selected
    end

    def known(yaml)
      yaml.keys - RESERVED
    end

    def sufficient_cli?(options)
      opt(options, :uri).to_s != "" || (opt(options, :host).to_s != "" && opt(options, :database).to_s != "")
    end

    def cli_env(options)
      {
        uri: opt(options, :uri),
        host: opt(options, :host),
        port: opt(options, :port),
        database: opt(options, :database),
        username: opt(options, :username),
        password: opt(options, :password),
        auth_source: opt(options, :auth_source)
      }.compact
    end

    def apply_cli!(selected, options)
      overrides = connection_overrides(options)
      if selected.size > 1 && overrides.any?
        raise Error, "Connection CLI flags are not allowed with multiple -e environments"
      end
      return if selected.size != 1

      env = selected.values.first
      overrides.each { |k, v| env[k] = v }
      merge_ssh!(env, options)
    end

    def connection_overrides(options)
      {
        uri: opt(options, :uri),
        host: opt(options, :host),
        port: opt(options, :port),
        database: opt(options, :database),
        username: opt(options, :username),
        password: opt(options, :password),
        auth_source: opt(options, :auth_source)
      }.compact.reject { |_, v| v.respond_to?(:empty?) && v.empty? }
    end

    def merge_ssh!(env, options)
      ssh = opt(options, :ssh)
      return if ssh.nil? || ssh.empty?

      env[:ssh] = (env[:ssh] || {}).merge(ssh.transform_keys(&:to_sym))
    end

    def assign_namespaces!(selected)
      selected.each do |name, env|
        env[:namespace] ||= camelize(name)
      end
    end

    def assert_unique_namespaces!(selected)
      groups = selected.group_by { |_, env| env[:namespace] }
      dup = groups.find { |_, pairs| pairs.size > 1 }
      return unless dup

      raise Error, "Environments share namespace #{dup.first}: #{dup.last.map(&:first).join(', ')}"
    end

    def camelize(name)
      name.split(/[^A-Za-z0-9]+/).reject(&:empty?).map { |p| p[0].upcase + p[1..] }.join
    end

    def stringify(hash)
      hash.to_h.transform_keys(&:to_s).transform_values { |v| v.is_a?(Hash) ? stringify(v) : v }
    end

    def deep_sym(obj)
      case obj
      when Hash then obj.to_h { |k, v| [k.to_sym, deep_sym(v)] }
      else obj
      end
    end

    def prefix_for(env_name)
      env_name.split(/[._-]/, 2).first
    end

    def client_name_for(env_name)
      env_name.gsub(/[^A-Za-z0-9]/, "_").to_sym
    end

    def opt(options, key)
      if options.respond_to?(key)
        options.public_send(key)
      elsif options.respond_to?(:[])
        options[key] || options[key.to_s]
      end
    end
  end
end
