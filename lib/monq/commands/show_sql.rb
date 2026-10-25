# frozen_string_literal: true

require "logger"
require "json"
require "monq/multi_io"

module Monq
  module Commands
    module ShowSql
      module Subscriber
        module_function

        def started(event)
          write("started", event)
        end

        def succeeded(event)
          write("succeeded", event)
        end

        def failed(event)
          write("failed", event)
        end

        def write(phase, event)
          io = App.log_io
          return unless io

          payload = {
            phase: phase,
            command_name: event.respond_to?(:command_name) ? event.command_name : nil,
            database: event.respond_to?(:database_name) ? event.database_name : nil,
            command: jsonable(event.respond_to?(:command) ? event.command : nil),
            duration: event.respond_to?(:duration) ? event.duration : nil
          }
          io.write("#{JSON.generate(payload)}\n")
        rescue StandardError
          nil
        end

        def jsonable(value)
          JSON.parse(JSON.generate(value))
        rescue StandardError
          value.to_s
        end
      end

      class << self
        attr_accessor :subscribed

        def enable
          App.log_io ||= MultiIO.new
          App.log_io << $stdout unless App.log_io.include?($stdout)
          subscribe!
          mirror_logger!
        end

        def disable
          return unless App.log_io.is_a?(MultiIO) && App.log_io.include?($stdout)

          App.log_io.delete($stdout)
        end

        def subscribe!
          return if subscribed
          return unless defined?(Mongo::Monitoring::COMMAND) && Mongo::Monitoring::Global.respond_to?(:subscribe)

          Mongo::Monitoring::Global.subscribe(Mongo::Monitoring::COMMAND, Subscriber)
          self.subscribed = true
        end

        def mirror_logger!
          return unless defined?(Mongo::Logger)

          Mongo::Logger.logger = Logger.new(App.log_io)
        end

        def register_pry_command!
          return if Pry.commands["show-sql"]

          Pry.commands.block_command("show-sql", "Print Mongo commands") do
            Monq::Commands::ShowSql.enable
          end

          Pry.commands.block_command("hide-sql", "Stop printing Mongo commands") do
            Monq::Commands::ShowSql.disable
          end
        end
      end
    end
  end
end
