# frozen_string_literal: true

module Monq
  module Ext
    CAP = 500

    def self.materialize(criteria)
      capped = limit_unset?(criteria.options)
      criteria = criteria.limit(CAP) if capped
      [criteria.to_a, capped]
    end

    def self.display_criteria(criteria, attrs = [], options = {})
      docs, capped = materialize(criteria)
      puts table_for(filter_docs(docs, attrs, options))
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

    def self.filter_docs(docs, attrs = [], options = {})
      unless docs.empty? || docs.first.is_a?(Hash) || !docs.first.respond_to?(:attributes)
        docs = docs.map(&:attributes)
      end
      return docs if docs.empty? || (attrs.empty? && !options[:except])

      column_names = docs.first.keys
      selected = attrs.flat_map { |e| e.is_a?(Regexp) ? column_names.grep(e) : e }.uniq

      if options[:except]
        selected = column_names if selected.empty?
        except = options[:except]
        if except.is_a?(Regexp)
          selected.reject! { |e| e =~ except }
        else
          selected -= [except].flatten
        end
      end

      docs.map { |doc| doc.slice(*selected) }
    end

    def self.limit_unset?(options)
      return true if options.nil?

      options[:limit].nil? && options["limit"].nil?
    end
  end
end
