# frozen_string_literal: true

module Monq
  module Ext
    module Document
      def t(*attrs, **options)
        [attributes].t(*attrs, **options)
      end

      def v(*attrs, **options)
        [attributes].v(*attrs, **options)
      end

      def vd(*attrs, **options)
        [attributes].vd(*attrs, **options)
      end

      def write_csv(filename)
        [self].write_csv(filename)
      end

      def write_excel(filename, sheet_name: "Sheet1")
        [self].write_excel(filename, sheet_name: sheet_name)
      end
    end
  end
end

Mongoid::Document.include(Monq::Ext::Document)
