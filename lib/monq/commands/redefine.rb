# frozen_string_literal: true

module Monq
  module Commands
    module Redefine
      module_function

      def run(envs)
        raise Error, "sandbox is active; run sandbox-quit first" if envs.any?(&:sandbox?)

        envs.each(&:redefine!)
      end
    end
  end
end

if defined?(Pry)
  Pry.commands.block_command("redefine", "Reload model files") do
    Monq::Commands::Redefine.run(Monq::App.instance.environments)
  end

  Pry.commands.alias_command "redef", "redefine"
end
