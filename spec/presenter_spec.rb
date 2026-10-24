# frozen_string_literal: true

require "bson"

RSpec.describe Monq::Presenter do
  it "stringifies ObjectId" do
    id = BSON::ObjectId.new
    expect(described_class.scalar(id)).to eq(id.to_s)
  end

  it "truncates long hashes" do
    text = described_class.scalar({ "a" => "x" * 200 })
    expect(text.length).to be <= 121
    expect(text).to end_with("…")
  end

  it "builds rows from the first document's keys" do
    rows = described_class.rows([{ "a" => 1, "b" => 2 }, { "a" => 3, "c" => 9 }])
    expect(rows.first).to eq(%w[a b])
    expect(rows.last).to eq([3, nil])
  end
end
