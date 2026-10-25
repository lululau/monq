# frozen_string_literal: true

require_relative "commands/info"
require_relative "commands/models"
require_relative "commands/show_sql"
require_relative "commands/reconnect"
require_relative "commands/redefine"
require_relative "commands/sandbox"

module Monq
  module Commands
    module_function

    def register_pry_commands!
      return unless defined?(Pry)

      Info.register_pry_command!
      Models.register_pry_command!
      ShowSql.register_pry_command!
      Reconnect.register_pry_command!
      Redefine.register_pry_command!
      Sandbox.register_pry_command!
    end
  end
end
