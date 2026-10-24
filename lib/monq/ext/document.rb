# frozen_string_literal: true

module Monq
  module Ext
    module Document
      def t
        [attributes].t
      end

      def v
        [attributes].v
      end

      def vd
        [attributes].vd
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
