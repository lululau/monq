# frozen_string_literal: true

module Monq
  module Ext
    module Criteria
      def t(*attrs, **options)
        Monq::Ext.display_criteria(self, attrs, options)
      end

      def v(*attrs, **options)
        docs, = Monq::Ext.materialize(self)
        docs.v(*attrs, **options)
      end

      def vd(*attrs, **options)
        t(*attrs, **options)
      end

      # Full result set. Display methods cap at 500; export must not.
      def write_csv(filename)
        to_a.write_csv(filename)
      end

      def write_excel(filename, sheet_name: "Sheet1")
        to_a.write_excel(filename, sheet_name: sheet_name)
      end
    end
  end
end

Mongoid::Criteria.include(Monq::Ext::Criteria)
