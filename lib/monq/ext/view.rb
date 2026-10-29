# frozen_string_literal: true

module Monq
  module Ext
    module View
      def t(*attrs, **options)
        materialized_docs.t(*attrs, **options)
      end

      def v(*attrs, **options)
        materialized_docs.v(*attrs, **options)
      end

      def vd(*attrs, **options)
        materialized_docs.vd(*attrs, **options)
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
