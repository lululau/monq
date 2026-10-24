# frozen_string_literal: true

require "ostruct"

RSpec.describe Monq::Config do
  let(:yaml) do
    {
      "default" => { "auth_source" => "admin" },
      "fof.dev" => { "uri" => "mongodb://h/db", "database" => "fof_dev", "namespace" => "Fof" },
      "ops.prod" => { "host" => "10.0.0.2", "database" => "ops" }
    }
  end

  it "rejects reserved environment names" do
    expect { described_class.select_environments(yaml, ["default"], OpenStruct.new) }
      .to raise_error(Monq::Error, /reserved/i)
  end

  it "fails when an -e name is missing" do
    expect { described_class.select_environments(yaml, ["nope"], OpenStruct.new) }
      .to raise_error(Monq::Error, /nope/)
  end

  it "does not treat the YAML default anchor as an environment when -e is absent" do
    expect { described_class.select_environments(yaml, nil, OpenStruct.new) }
      .to raise_error(Monq::Error, /-e/)
  end

  it "slices only requested environments" do
    envs = described_class.select_environments(yaml, ["fof.dev"], OpenStruct.new)
    expect(envs.keys).to eq(["fof.dev"])
  end

  it "builds a synthetic default from CLI when -e is absent but uri is present" do
    opts = OpenStruct.new(uri: "mongodb://h/x", database: "x")
    envs = described_class.select_environments({}, nil, opts)
    expect(envs.keys).to eq(["default"])
    expect(envs["default"][:uri]).to eq("mongodb://h/x")
  end

  it "rejects two environments that share a namespace" do
    yaml["ops.prod"]["namespace"] = "Fof"
    expect { described_class.select_environments(yaml, ["fof.dev", "ops.prod"], OpenStruct.new) }
      .to raise_error(Monq::Error, /namespace/i)
  end
end
