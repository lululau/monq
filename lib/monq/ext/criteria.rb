# frozen_string_literal: true

module Monq
  module Ext
    module Criteria
      def t
        Monq::Ext.display_criteria(self)
      end

      def v
        docs, = Monq::Ext.materialize(self)
        docs.v
      end

      def vd
        t
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
