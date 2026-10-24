# frozen_string_literal: true

RSpec.describe "const_missing" do
  it "resolves the first environment that defines the constant" do
    a = Module.new
    b = Module.new
    klass = Class.new
    a.const_set(:FundProbe, klass)
    app = instance_double(Monq::App, environments: [
      instance_double(Monq::Environment, namespace_module: a),
      instance_double(Monq::Environment, namespace_module: b)
    ])
    allow(Monq::App).to receive(:instance).and_return(app)
    expect(Object.const_missing(:FundProbe)).to eq(klass)
  end

  it "falls through when no environment defines it" do
    app = instance_double(Monq::App, environments: [])
    allow(Monq::App).to receive(:instance).and_return(app)
    expect { Object.const_missing(:DefinitelyMissingZz) }.to raise_error(NameError)
  end
end

RSpec.describe "Kernel helpers" do
  it "warns and returns nil when more than one environment is loaded" do
    a = Module.new
    b = Module.new
    app = instance_double(Monq::App, environments: [
      instance_double(Monq::Environment, namespace_module: a),
      instance_double(Monq::Environment, namespace_module: b)
    ])
    allow(Monq::App).to receive(:instance).and_return(app)

    expect { expect(q(hello: 1)).to be_nil }.to output(/Namespace\.q/).to_stderr
  end

  it "delegates q to the only environment's client" do
    result = double("command result")
    database = double("database", command: result)
    client = double("client", database: database)
    env = instance_double(Monq::Environment, client: client)
    app = instance_double(Monq::App, environments: [env])
    allow(Monq::App).to receive(:instance).and_return(app)

    expect(q(hello: 1)).to eq(result)
    expect(database).to have_received(:command).with(hello: 1)
  end
end
