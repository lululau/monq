# frozen_string_literal: true

require "csv"
require "tmpdir"

RSpec.describe Array do
  it "writes csv without the 500-row display cap" do
    path = File.join(Dir.tmpdir, "monq-export-#{Process.pid}.csv")
    [{ "a" => 1 }, { "a" => 2 }].write_csv(path)
    rows = CSV.read(path)
    expect(rows.size).to eq(3)
    expect(rows.first).to eq(["a"])
  ensure
    File.delete(path) if path && File.exist?(path)
  end

  it "exports columns missing from the first row" do
    path = File.join(Dir.tmpdir, "monq-export-#{Process.pid}.csv")
    [{ "a" => 1 }, { "a" => 2, "b" => 3 }].write_csv(path)
    rows = CSV.read(path)
    expect(rows.first).to eq(%w[a b])
    expect(rows).to eq([%w[a b], ["1", ""], %w[2 3]])
  ensure
    File.delete(path) if path && File.exist?(path)
  end
end
