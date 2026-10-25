# frozen_string_literal: true

RSpec.describe Monq::Commands::Info do
  it "masks passwords" do
    env = instance_double(
      Monq::Environment,
      name: "blog.dev",
      config: { uri: "mongodb://admin:secret@db.example.com:27017/blog_dev", database: "blog_dev" },
      client_name: :blog_dev,
      ping?: true,
      ssh_proxy: nil
    )
    text = described_class.render([env], /blog/)
    expect(text).to include("admin:***@")
    expect(text).not_to include("secret")
    expect(text).to include("blog_dev")
  end
end

RSpec.describe Monq::Commands::Models do
  ModelRow = Struct.new(:name, :storage_options)

  def model_env(models)
    instance_double(
      Monq::Environment,
      name: "blog.dev",
      models: models,
      namespace_module: Module.new
    )
  end

  it "filters by collection name or model class name" do
    user = ModelRow.new("Blog::User", { collection: "users" })
    order = ModelRow.new("Blog::Order", { collection: "orders" })
    text = described_class.render([model_env([user, order])], nil, "user")

    expect(text).to include("users")
    expect(text).not_to include("orders")
  end

  it "accepts a slash-delimited regexp" do
    user = ModelRow.new("Blog::User", { collection: "users" })
    text = described_class.render([model_env([user])], nil, "/order/i")

    expect(text).not_to include("users")
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
