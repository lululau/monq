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
    end
  end
end

Mongoid::Criteria.include(Monq::Ext::Criteria)
