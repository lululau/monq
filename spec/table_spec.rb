# frozen_string_literal: true

RSpec.describe Monq::Presenter do
  describe ".column_names" do
    it "unions keys across all docs" do
      docs = [{ "_id" => 1, "name" => "old" }, { "_id" => 2, "fund_alias" => "x" }]
      expect(described_class.column_names(docs)).to eq(["_id", "name", "fund_alias"])
    end
  end

  describe ".rows" do
    it "uses the union of keys and pads missing values" do
      docs = [{ "a" => 1 }, { "b" => 2 }]
      expect(described_class.rows(docs)).to eq([%w[a b], [1, nil], [nil, 2]])
    end
  end
end

RSpec.describe Monq::Ext do
  describe ".filter_docs" do
    it "matches regexp columns present in any doc, not only the first" do
      docs = [{ "_id" => 1, "name" => "old" }, { "_id" => 2, "fund_alias" => "111 Capital MLP" }]
      expect(described_class.filter_docs(docs, [/alias/], {}))
        .to eq([{}, { "fund_alias" => "111 Capital MLP" }])
    end

    it "keeps every column for the except option" do
      docs = [{ "a" => 1 }, { "b" => 2 }]
      expect(described_class.filter_docs(docs, [], { except: /a/ })).to eq([{}, { "b" => 2 }])
    end
  end

  describe ".table_for with column filtering" do
    it "renders columns that only later docs have" do
      docs = [{ "_id" => 1, "name" => "old" }, { "_id" => 2, "fund_alias" => "111 Capital MLP" }]
      table = Monq::Ext.table_for(Monq::Ext.filter_docs(docs, [/alias/], {}))
      expect(table).to include("fund_alias")
      expect(table).to include("111 Capital MLP")
    end
  end
end
