# frozen_string_literal: true

require "monq/table"

module Monq
  module Commands
    module Models
      HEADERS = ["Table Name", "Model Class", "Abbr"].freeze

      module_function

      def render(envs, env_regexp = nil, collection_regexp = nil, format: "terminal")
        envs.filter_map { |env| render_env(env, collection_regexp, format) if match_env?(env, env_regexp) }.join("\n")
      end

      def render_env(env, collection_regexp, format)
        Table.new("Environment: #{env.name}") do |table|
          table.headers = HEADERS
          Array(env.models).each do |klass|
            collection = collection_name(klass)
            next unless match_collection?(klass, collection, collection_regexp)

            table.body << [collection, klass.name, abbreviation(env, klass)]
          end
        end.to_terminal(format)
      end

      def match_collection?(klass, collection, collection_regexp)
        regexp = coerce_regexp(collection_regexp)
        return true unless regexp

        collection.to_s =~ regexp || klass.name.to_s =~ regexp
      end

      def coerce_regexp(value)
        return nil if value.nil? || value.to_s.empty?
        return value if value.is_a?(Regexp)

        source = value.to_s
        if source.start_with?("/") && source.end_with?("/") && source.length > 1
          Regexp.new(source[1..-2])
        else
          Regexp.new(source, Regexp::IGNORECASE)
        end
      end

      def match_env?(env, env_regexp)
        return true if env_regexp.nil? || env_regexp.to_s.empty?

        env.name =~ coerce_regexp(env_regexp)
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

      def register_pry_command!
        return if Pry.commands["m"]

        Pry.commands.create_command("m", "List loaded models: m [-e env] [-f format] [collection_regexp]") do
          def options(opt)
            opt.on "-e", "--env", "Environment name regexp", argument: true, as: String
            opt.on "-f", "--format", "Table format: terminal, md, org", argument: true, as: String, default: "terminal"
          end

          def process
            output.puts Monq::Commands::Models.render(
              Monq::App.instance.environments,
              opts[:env],
              args.first,
              format: opts[:format] || "terminal"
            )
          end
        end

        Pry.commands.alias_command "l", "m"
      end
    end
  end
end
