# frozen_string_literal: true

module Monq
  module Commands
    module Reconnect
      module_function

      def run(envs, force: false)
        raise Error, "sandbox is active; run sandbox-quit first" if envs.any?(&:sandbox?)

        envs.each do |env|
          reconnect_ssh(env, force: force)
          if force
            env.reconnect!
          else
            env.reconnect! unless env.ping?
          end
        end
      end

      def reconnect_ssh(env, force:)
        proxy = env.ssh_proxy
        return unless proxy

        if force
          proxy.reconnect! if proxy.respond_to?(:reconnect!)
        elsif proxy.respond_to?(:reconnect)
          proxy.reconnect
        end
      end

      def register_pry_command!
        return if Pry.commands["reconnect"]

        Pry.commands.block_command("reconnect", "Reconnect dead clients") do
          Monq::Commands::Reconnect.run(Monq::App.instance.environments, force: false)
        end

        Pry.commands.block_command("reconnect!", "Force reconnect clients") do
          Monq::Commands::Reconnect.run(Monq::App.instance.environments, force: true)
        end
      end
    end
  end
end
