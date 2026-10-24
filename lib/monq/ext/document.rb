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
    end
  end
end

Mongoid::Document.include(Monq::Ext::Document)
