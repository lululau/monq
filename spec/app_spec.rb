# frozen_string_literal: true

require "tempfile"
require "ostruct"

RSpec.describe Monq::Cli do
  it "parses multiple environments" do
    opts = described_class.parse!(%w[-e fof.dev,ops.prod])
    expect(opts.environments).to eq(%w[fof.dev ops.prod])
  end

  it "rejects connection flags with multiple environments" do
    expect { described_class.parse!(%w[-e a,b --uri mongodb://h/db]) }
      .to raise_error(Monq::Error, /multiple/i)
  end
end

RSpec.describe Monq::App do
  it "evals -E and does not start pry" do
    yaml = Tempfile.new(["monq", ".yml"])
    yaml.write("fof.dev:\n  host: h\n  database: d\n  namespace: FofApp\n")
    yaml.close
    app = described_class.new(OpenStruct.new(config_file: yaml.path, environments: ["fof.dev"], code: "MONQ_RAN = 1"))
    allow_any_instance_of(Monq::Environment).to receive(:connect!)
    expect(Pry).not_to receive(:start) if defined?(Pry)
    app.run!
    expect(MONQ_RAN).to eq(1)
  ensure
    yaml&.unlink
    Object.send(:remove_const, :FofApp) if Object.const_defined?(:FofApp)
    Object.send(:remove_const, :MONQ_RAN) if Object.const_defined?(:MONQ_RAN)
  end
end
