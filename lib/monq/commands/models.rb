# frozen_string_literal: true

require "monq/table"

module Monq
  module Commands
    module Models
      HEADERS = ["Table Name", "Model Class", "Abbr"].freeze

      module_function

      def render(envs, env_regexp = nil, format: "terminal")
        envs.filter_map { |env| render_env(env, format) if match_env?(env, env_regexp) }.join("\n")
      end

      def render_env(env, format)
        Table.new("Environment: #{env.name}") do |table|
          table.headers = HEADERS
          Array(env.models).each do |klass|
            table.body << [collection_name(klass), klass.name, abbreviation(env, klass)]
          end
        end.to_terminal(format)
      end

      def match_env?(env, env_regexp)
        return true if env_regexp.nil? || env_regexp.to_s.empty?

        regexp = env_regexp.is_a?(Regexp) ? env_regexp : Regexp.new(env_regexp.to_s)
        env.name =~ regexp
      end

      def collection_name(klass)
        options = klass.storage_options
        options[:collection] || options["collection"]
      rescue StandardError
        nil
      end

      def abbreviation(env, klass)
        mod = env.namespace_module
        mod.constants.each do |name|
          next if name.to_s == klass.name.to_s.split("::").last

          return name.to_s if mod.const_get(name) == klass
        end
        ""
      rescue StandardError
        ""
      end
    end
  end
end

if defined?(Pry)
  Pry.commands.create_command("m", "List loaded models") do
    def options(opt)
      opt.on "-e", "--env", "Environment name regexp", argument: true, as: String
      opt.on "-f", "--format", "Table format: terminal, md, org", argument: true, as: String, default: "terminal"
    end

    def process
      output.puts Monq::Commands::Models.render(
        Monq::App.instance.environments,
        opts[:env],
        format: opts[:format] || "terminal"
      )
    end
  end

  Pry.commands.alias_command "l", "m"
end
