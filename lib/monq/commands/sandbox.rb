# frozen_string_literal: true

module Monq
  module Commands
    module Sandbox
      module_function

      def enter(envs)
        return warn("already in sandbox") if envs.any?(&:sandbox?)

        hellos = envs.map { |env| env.client.database.command(hello: 1).documents.first }
        if hellos.any? { |doc| !transaction_capable?(doc) }
          raise Error, "current deployment does not support transactions (need replica set or mongos); not entering sandbox"
        end

        started = []
        envs.each do |env|
          session = env.client.start_session
          session.start_transaction
          env.bind_session(session)
          started << [env, session]
        rescue StandardError
          started.reverse_each do |e, s|
            s.abort_transaction
            s.end_session
            e.clear_session
          end
          raise
        end
      end

      def quit(envs)
        envs.each(&:clear_session)
      end

      def transaction_capable?(doc)
        return false if doc.nil?

        set_name = doc["setName"] || doc[:setName]
        msg = doc["msg"] || doc[:msg]
        !set_name.nil? || msg == "isdbgrid"
      end
    end
  end
end

if defined?(Pry)
  Pry.commands.block_command("sandbox-enter", "Start an all-or-nothing transaction on every environment") do
    Monq::Commands::Sandbox.enter(Monq::App.instance.environments)
  end

  Pry.commands.block_command("sandbox-quit", "Abort sandbox transactions and end their sessions") do
    Monq::Commands::Sandbox.quit(Monq::App.instance.environments)
  end
end
