# frozen_string_literal: true

RSpec.describe Monq::Environment do
  let(:hello_doc) { { "ok" => 1, "setName" => "rs0" } }
  let(:fake_client) do
    db = double("db", command: double(documents: [hello_doc]), collection_names: ["Fund_approved"])
    instance_double("Mongo::Client", database: db, close: nil)
  end

  before do
    allow(Mongo::Client).to receive(:new).and_return(fake_client)
    allow(Mongoid::Clients).to receive(:set)
  end

  it "registers the named client and maps the first env to :default" do
    env = described_class.new("fof.dev", { uri: "mongodb://h/fof_dev", database: "fof_dev", namespace: "Fof" }, first: true, model_dir: "/tmp")
    env.connect!
    expect(Mongoid::Clients).to have_received(:set).with(:fof_dev, fake_client)
    expect(Mongoid::Clients).to have_received(:set).with(:default, fake_client)
    expect(env.namespace).to eq("Fof")
    expect(env.ping?).to eq(true)
  end

  it "does not map later environments onto :default" do
    env = described_class.new("ops.prod", { host: "h", database: "ops", namespace: "Ops" }, first: false, model_dir: "/tmp")
    env.connect!
    expect(Mongoid::Clients).to have_received(:set).with(:ops_prod, fake_client)
    expect(Mongoid::Clients).not_to have_received(:set).with(:default, fake_client)
  end
end
