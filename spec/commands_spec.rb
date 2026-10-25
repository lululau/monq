# frozen_string_literal: true

RSpec.describe Monq::Commands::Info do
  it "masks passwords" do
    env = instance_double(
      Monq::Environment,
      name: "fof.dev",
      config: { uri: "mongodb://admin:secret@10.0.0.12:27017/fof_dev", database: "fof_dev" },
      client_name: :fof_dev,
      ping?: true,
      ssh_proxy: nil
    )
    text = described_class.render([env], /fof/)
    expect(text).to include("admin:***@")
    expect(text).not_to include("secret")
    expect(text).to include("fof_dev")
  end
end

RSpec.describe Monq::Commands::Models do
  ModelRow = Struct.new(:name, :storage_options)

  def model_env(models)
    instance_double(
      Monq::Environment,
      name: "fof.dev",
      models: models,
      namespace_module: Module.new
    )
  end

  it "filters by collection name or model class name" do
    fund = ModelRow.new("Fof::Fund", { collection: "Fund_approved" })
    aum = ModelRow.new("Fof::Aum", { collection: "Aum_approved" })
    text = described_class.render([model_env([fund, aum])], nil, "fund")

    expect(text).to include("Fund_approved")
    expect(text).not_to include("Aum_approved")
  end

  it "accepts a slash-delimited regexp" do
    fund = ModelRow.new("Fof::Fund", { collection: "Fund_approved" })
    text = described_class.render([model_env([fund])], nil, "/aum/i")

    expect(text).not_to include("Fund_approved")
  end
end

RSpec.describe Monq::Commands::Redefine do
  it "refuses while sandbox is active" do
    env = instance_double(Monq::Environment, sandbox?: true)
    expect { described_class.run([env]) }.to raise_error(Monq::Error, /sandbox/)
  end
end

RSpec.describe Monq::Commands::Reconnect do
  it "refuses while sandbox is active" do
    env = instance_double(Monq::Environment, sandbox?: true)
    expect { described_class.run([env]) }.to raise_error(Monq::Error, /sandbox/)
  end
end

RSpec.describe Monq::Commands do
  it "registers Pry commands after Pry is loaded" do
    require "pry"
    described_class.register_pry_commands!

    %w[info m l show-sql hide-sql reconnect reconnect! redefine redef sandbox-enter sandbox-quit].each do |name|
      expect(Pry.commands[name]).not_to be_nil, "expected Pry command #{name} to be registered"
    end
  end
end
