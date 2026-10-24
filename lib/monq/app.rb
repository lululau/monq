# frozen_string_literal: true

module Monq
  class App
    CONFIG_CANDIDATES = %w[~/.monq.d/init.yml ~/.monq.d/init.yaml ~/.monq.yml ~/.monq.yaml].freeze
    INITIALIZER_CANDIDATES = %w[~/.monq.d/init.rb ~/.monq.rb].freeze

    attr_reader :environments, :options

    class << self
      attr_accessor :instance
    end

    def initialize(options)
      @options = options
      self.class.instance = self
      @environments = build_environments
    end

    def run!
      @environments.each(&:connect!)
      load_initializer!
      @environments.each(&:load_models!)
      if @options.code && !@options.code.empty?
        eval(@options.code, TOPLEVEL_BINDING, "-e")
      elsif @options.args&.first
        load(@options.args.first)
      elsif !$stdin.isatty
        eval($stdin.read, TOPLEVEL_BINDING, "stdin")
      else
        require "monq/repl"
        Repl.new.start
      end
    end

    private

    def build_environments
      path = resolve_config_path
      yaml = path ? Config.load_file(path) : {}
      selected = Config.select_environments(yaml, @options.environments, @options)
      model_dir = File.expand_path("~/.monq.d")
      selected.each_with_index.map do |(name, conf), index|
        Environment.new(name, conf, first: index.zero?, model_dir: model_dir)
      end
    end

    def resolve_config_path
      if config_file_set?
        path = File.expand_path(@options.config_file)
        raise Error, "Config file not found: #{@options.config_file}" unless File.file?(path)

        return path
      end

      found = CONFIG_CANDIDATES.map { |candidate| File.expand_path(candidate) }.find { |path| File.file?(path) }
      return found if found
      return nil if Config.sufficient_cli?(@options)

      raise Error, "No config file found. Create ~/.monq.d/init.yml or pass -e / --uri"
    end

    def config_file_set?
      value = @options.respond_to?(:config_file) ? @options.config_file : nil
      value && !value.empty?
    end

    def load_initializer!
      if initializer_set?
        path = File.expand_path(@options.initializer)
        raise Error, "Initializer not found: #{@options.initializer}" unless File.file?(path)

        load(path)
        return
      end

      path = INITIALIZER_CANDIDATES.map { |candidate| File.expand_path(candidate) }.find { |candidate| File.file?(candidate) }
      load(path) if path
    end

    def initializer_set?
      value = @options.respond_to?(:initializer) ? @options.initializer : nil
      value && !value.empty?
    end
  end
end
