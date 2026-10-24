# frozen_string_literal: true

require "pry"
require_relative "commands"

module Monq
  class Repl
    def start
      unless App.instance.options.babel_compatable
        names = App.instance.environments.map(&:name).join("+")
        Pry.config.prompt = Pry::Prompt.new(
          "monq",
          "monq",
          [proc { |*| "MONQ@#{names} ❯ " }]
        )
      end
      Pry.start
    end
  end
end
