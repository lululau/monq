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
