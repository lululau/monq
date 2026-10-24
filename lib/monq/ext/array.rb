# frozen_string_literal: true

class Array
  def t
    puts Monq::Ext.table_for(hash_docs)
    nil
  end

  def v
    Monq::Ext.vertical(hash_docs)
  end

  # visidata comes later; always print the table so vd works without the binary.
  def vd
    t
  end

  private

  def hash_docs
    return self if empty?
    return self if first.is_a?(Hash)

    if first.respond_to?(:attributes)
      map { |item| item.attributes }
    else
      self
    end
  end
end
