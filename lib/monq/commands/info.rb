# frozen_string_literal: true

module Monq
  module Commands
    module Info
      module_function

      def render(envs, regexp)
        envs.select { |env| env.name =~ regexp }.map { |env| format_env(env) }.join
      end

      def format_env(env)
        config = env.config || {}
        database = config[:database] || config["database"]
        uri = Config.mask_uri(config[:uri] || config["uri"])
        proxy = env.ssh_proxy
        ssh = if proxy
                active = proxy.respond_to?(:active?) ? proxy.active? : false
                port = proxy.respond_to?(:local_port) ? proxy.local_port : nil
                "ssh: active=#{active} local_port=#{port}"
              else
                "ssh: none"
              end

        <<~INFO
          #{env.name}
            database: #{database}
            client: #{env.client_name}
            ping: #{env.ping?}
            uri: #{uri}
            #{ssh}
        INFO
      end
    end
  end
end

if defined?(Pry)
  Pry.commands.block_command("info", "Show connection info for matching environments") do |pattern|
    pattern = Regexp.new(pattern || ".*", Regexp::IGNORECASE)
    output.puts Monq::Commands::Info.render(Monq::App.instance.environments, pattern)
  end
end
