# frozen_string_literal: true

require "pry"
require "rainbow"
require_relative "commands"

module Monq
  class Repl
    def start
      Commands.register_pry_commands!
      unless App.instance.options.babel_compatable
        Pry.config.prompt = Pry::Prompt.new("monq", "monq", prompt)
      end
      Pry.start
    end

    def prompt
      [proc do |obj, nest_level, pry_instance|
        names = App.instance.environments.map(&:name).join("+")
        "%s#{Rainbow('@').green}%s%s%s [%d] %s " % [
          Rainbow("MONQ").red,
          Rainbow(names).yellow,
          sandbox_indicator,
          context_prompt(obj, nest_level),
          pry_instance.input_ring.count,
          Rainbow("❯").green
        ]
      end]
    end

    def context_prompt(obj, nest_level)
      if nest_level.zero?
        "(#{obj})"
      else
        "(#{obj}:#{nest_level})"
      end
    end

    def sandbox_indicator
      return "" unless App.instance.environments.any?(&:sandbox?)

      " [%s] " % Rainbow("sandbox").green.bright
    end
  end
end
