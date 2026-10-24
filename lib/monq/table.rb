# frozen_string_literal: true

require "terminal-table"

module Monq
  class Table
    attr_accessor :caption, :headers, :body

    def initialize(caption = nil)
      @caption = caption
      @headers = []
      @body = []
      yield self if block_given?
    end

    def to_terminal(format = "terminal")
      style = terminal_style_for_format(format)
      tbl = Terminal::Table.new do |table|
        table.style = style
        table << (headers || [])
        table << :separator
        (body || []).each { |row| table << row }
      end

      title = caption ? "#{caption}\n---------------------------------------\n\n" : ""
      rendered = case format.to_s
                 when "md"
                   tbl.to_s.lines.map { |line| "  #{line}" }.join
                 when "org"
                   tbl.to_s.lines.map { |line| "  #{line.gsub(/^\+|\+$/, "|")}" }.join
                 else
                   tbl.to_s
                 end
      "#{title}#{rendered}"
    end

    private

    def terminal_style_for_format(format)
      case format.to_s
      when "md"
        { border_top: false, border_bottom: false, border_i: "|" }
      when "org"
        { border_top: false, border_bottom: false }
      else
        {}
      end
    end
  end
end
