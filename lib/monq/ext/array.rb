# frozen_string_literal: true

class Array
  def t(*attrs, **options)
    puts Monq::Ext.table_for(Monq::Ext.filter_docs(hash_docs, attrs, options))
    nil
  end

  def v(*attrs, **options)
    Monq::Ext.vertical(Monq::Ext.filter_docs(hash_docs, attrs, options))
  end

  # visidata comes later; always print the table so vd works without the binary.
  def vd(*attrs, **options)
    t(*attrs, **options)
  end

  def write_csv(filename)
    require "csv"
    docs = respond_to?(:hash_docs, true) ? hash_docs : self
    File.open(filename, "w:UTF-8") do |file|
      csv = CSV.new(file)
      return if docs.empty?

      keys = Monq::Presenter.column_names(docs)
      csv << keys.map(&:to_s)
      docs.each { |row| csv << keys.map { |k| row[k].to_s } }
    end
  end

  def write_excel(filename, sheet_name: "Sheet1")
    require "caxlsx"
    docs = hash_docs
    package = Axlsx::Package.new
    package.workbook.add_worksheet(name: sheet_name) do |sheet|
      next if docs.empty?

      keys = Monq::Presenter.column_names(docs)
      sheet.add_row(keys.map(&:to_s))
      docs.each { |row| sheet.add_row(keys.map { |k| row[k].to_s }) }
    end
    package.serialize(filename)
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
