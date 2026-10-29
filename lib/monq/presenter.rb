# frozen_string_literal: true

require "json"
require "bson"

module Monq
  module Presenter
    module_function

    def scalar(value)
      case value
      when BSON::ObjectId
        value.to_s
      when Time, Date
        value.strftime("%Y-%m-%d %H:%M:%S")
      when BSON::Binary
        "#<BSON::Binary type=#{value.type} size=#{value.data.bytesize}>"
      when BSON::Decimal128
        value.to_s
      when Hash, Array
        json = JSON.generate(as_json_tree(value))
        json.length > 120 ? "#{json[0, 120]}…" : json
      else
        value.respond_to?(:as_json) ? value.as_json : value.to_s
      end
    end

    def rows(docs)
      return [] if docs.nil? || docs.empty?

      docs = docs.map { |doc| doc.is_a?(Hash) || !doc.respond_to?(:attributes) ? doc : doc.attributes }
      keys = docs.first.keys
      body = docs.map { |doc| keys.map { |key| scalar(doc[key]) } }
      [keys, *body]
    end

    def as_json_tree(value)
      case value
      when BSON::ObjectId, BSON::Decimal128
        value.to_s
      when BSON::Binary
        "#<BSON::Binary type=#{value.type} size=#{value.data.bytesize}>"
      when Time, Date
        value.strftime("%Y-%m-%d %H:%M:%S")
      when Hash
        value.each_with_object({}) { |(key, item), hash| hash[key] = as_json_tree(item) }
      when Array
        value.map { |item| as_json_tree(item) }
      else
        value.respond_to?(:as_json) ? value.as_json : value.to_s
      end
    end
    private_class_method :as_json_tree
  end
end
