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

RSpec.describe Monq::Config do
  describe ".client_options" do
    it "prefers uri and lets database override the URI path" do
      opts = described_class.client_options(uri: "mongodb://u:p@10.0.0.12:27017/other?authSource=admin", database: "fof_dev")
      expect(opts[:database]).to eq("fof_dev")
      expect(opts[:hosts]).to eq(["10.0.0.12:27017"])
    end

    it "requires database when the URI has no path" do
      expect { described_class.client_options(uri: "mongodb://10.0.0.12:27017/?authSource=admin") }
        .to raise_error(Monq::Error, /database/)
    end

    it "builds hosts from split fields when uri is absent" do
      opts = described_class.client_options(host: "10.0.0.1", database: "x")
      expect(opts[:hosts]).to eq(["10.0.0.1:27017"])
      expect(opts[:database]).to eq("x")
    end

    it "rewrites ssh to one direct seed and drops replica_set" do
      opts = described_class.client_options(
        uri: "mongodb://u:p@10.0.0.12:27017,10.0.0.13:27017/fof_dev?replicaSet=rs0",
        ssh: { local_host: "127.0.0.1", local_port: 27018 }
      )
      expect(opts[:hosts]).to eq(["127.0.0.1:27018"])
      expect(opts[:options][:direct_connection]).to eq(true)
      expect(opts[:options]).not_to have_key(:replica_set)
    end

    it "rejects mongodb+srv together with ssh" do
      expect {
        described_class.client_options(uri: "mongodb+srv://u:p@cluster.example/?authSource=admin", database: "x", ssh: { local_port: 1 })
      }.to raise_error(Monq::Error, /srv/i)
    end
  end

  describe ".mask_uri" do
    it "masks the password" do
      expect(described_class.mask_uri("mongodb://admin:secret@10.0.0.12:27017/db"))
        .to eq("mongodb://admin:***@10.0.0.12:27017/db")
    end
  end

  it "maps env name to prefix and client name" do
    expect(described_class.prefix_for("fof.dev")).to eq("fof")
    expect(described_class.client_name_for("fof.dev")).to eq(:fof_dev)
    expect(described_class.camelize("fof.dev")).to eq("FofDev")
  end
end
