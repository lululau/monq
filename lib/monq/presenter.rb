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
      keys = column_names(docs)
      body = docs.map { |doc| keys.map { |key| scalar(doc[key]) } }
      [keys, *body]
    end

    # Union of keys across all docs: Mongoid documents only carry the fields
    # actually stored on each one, so any single doc (e.g. the oldest row in a
    # natural-order cursor) can miss fields present in the rest.
    def column_names(docs)
      docs.flat_map { |doc| doc.is_a?(Hash) || !doc.respond_to?(:attributes) ? doc.keys : doc.attributes.keys }.uniq
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
