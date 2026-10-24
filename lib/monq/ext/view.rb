# frozen_string_literal: true

module Monq
  module Ext
    module View
      def t
        materialized_docs.t
      end

      def v
        materialized_docs.v
      end

      def vd
        materialized_docs.vd
      end

      # Full result set. Display methods cap at 500; export must not.
      def write_csv(filename)
        to_a.write_csv(filename)
      end

      def write_excel(filename, sheet_name: "Sheet1")
        to_a.write_excel(filename, sheet_name: sheet_name)
      end

      private

      def materialized_docs
        view = self
        if respond_to?(:options) && respond_to?(:limit) && Monq::Ext.limit_unset?(options)
          view = limit(Monq::Ext::CAP)
        end
        view.to_a
      end
    end
  end
end

Mongo::Collection::View.include(Monq::Ext::View)
