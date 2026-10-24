# frozen_string_literal: true

module Monq
  class MultiIO
    ANSI = /\e\[(\d+)(?:;\d+)*m/.freeze

    def initialize(*targets)
      @targets = targets
    end

    def write(*args)
      @targets.each do |target|
        if tty?(target)
          target.write(*args)
        else
          target.write(*args.map { |str| strip_ansi(str) })
        end
        target.flush if target.respond_to?(:flush)
      end
    end

    def <<(target)
      @targets << target
      self
    end

    def close
      @targets.each { |target| target.close if target.respond_to?(:close) }
    end

    def delete(io)
      @targets.delete(io)
    end

    def include?(io)
      @targets.include?(io)
    end

    private

    def tty?(target)
      target.respond_to?(:isatty) ? target.isatty : false
    end

    def strip_ansi(value)
      value.to_s.gsub(ANSI, "")
    end
  end
end
