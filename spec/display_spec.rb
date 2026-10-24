# frozen_string_literal: true

RSpec.describe "display" do
  it "caps an unlimited criteria at 500 and reports it" do
    criteria = double("criteria", options: {})
    allow(criteria).to receive(:limit).with(500).and_return(criteria)
    docs = [{ "_id" => "a", "name" => "n" }]
    allow(criteria).to receive(:to_a).and_return(docs)
    expect { Monq::Ext.display_criteria(criteria) }.to output(/capped at 500/).to_stdout
  end

  it "does not cap when the caller set limit" do
    criteria = double("criteria", options: { limit: 2 })
    expect(criteria).not_to receive(:limit)
    allow(criteria).to receive(:to_a).and_return([{ "_id" => "a" }])
    expect { Monq::Ext.display_criteria(criteria) }.not_to output(/capped/).to_stdout
  end
end
