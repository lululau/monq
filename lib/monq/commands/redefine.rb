# frozen_string_literal: true

module Monq
  module Commands
    module Redefine
      module_function

      def run(envs)
        raise Error, "sandbox is active; run sandbox-quit first" if envs.any?(&:sandbox?)

        envs.each(&:redefine!)
      end

      def register_pry_command!
        return if Pry.commands["redefine"]

        Pry.commands.block_command("redefine", "Reload model files") do
          Monq::Commands::Redefine.run(Monq::App.instance.environments)
        end

        Pry.commands.alias_command "redef", "redefine"
      end
    end
  end
end
