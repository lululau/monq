# frozen_string_literal: true

module Monq
  module Ext
    CAP = 500

    def self.materialize(criteria)
      capped = limit_unset?(criteria.options)
      criteria = criteria.limit(CAP) if capped
      [criteria.to_a, capped]
    end

    def self.display_criteria(criteria)
      docs, capped = materialize(criteria)
      puts table_for(docs)
      puts "showing #{docs.size} rows (capped at #{CAP})" if capped
      nil
    end

    def self.table_for(docs)
      rows = Presenter.rows(docs)
      Table.new do |table|
        table.headers = rows.first || []
        table.body = rows[1..] || []
      end.to_terminal
    end

    def self.vertical(docs)
      rows = Presenter.rows(docs)
      return [] if rows.empty?

      keys = rows.first
      [keys, nil, *rows[1..]]
    end

    def self.limit_unset?(options)
      return true if options.nil?

      options[:limit].nil? && options["limit"].nil?
    end
  end
end
