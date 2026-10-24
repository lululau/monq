# frozen_string_literal: true

require "fileutils"
require "tmpdir"

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

  it "loads prefix file into the namespace and rebinds :default client" do
    dir = Dir.mktmpdir
    File.write(File.join(dir, "fof.rb"), <<~RUBY)
      class Fund
        include Mongoid::Document
        store_in collection: "Fund_approved"
        embeds_one :meta, class_name: "FundMeta"
      end
      class FundMeta
        include Mongoid::Document
        embedded_in :fund
        field :status, type: String
      end
    RUBY

    env = described_class.new("fof.dev", { host: "h", database: "d", namespace: "Fof" }, first: true, model_dir: dir)
    allow(env).to receive(:connect!)
    env.load_models!
    expect(Fof::Fund.storage_options[:client]).to eq(:fof_dev)
    expect(Fof::Fund.storage_options[:collection]).to eq("Fund_approved")
    expect(Fof::FundMeta).to be_embedded
    expect(Fof.const_defined?(:F)).to eq(true)
  ensure
    Object.send(:remove_const, :Fof) if Object.const_defined?(:Fof)
    FileUtils.remove_entry(dir) if dir
  end

  it "warns and continues when the prefix file is missing" do
    dir = Dir.mktmpdir
    env = described_class.new("fof.dev", { host: "h", database: "d", namespace: "FofX" }, first: true, model_dir: dir)
    expect { env.load_models! }.to output(/fof\.rb/).to_stderr
    expect(env.models).to eq([])
  ensure
    Object.send(:remove_const, :FofX) if Object.const_defined?(:FofX)
    FileUtils.remove_entry(dir) if dir
  end
end
