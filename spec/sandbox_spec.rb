# frozen_string_literal: true

RSpec.describe Monq::Commands::Sandbox do
  def sandbox_env(hello, name: "fof.dev")
    client = double("client")
    db = double("db")
    allow(client).to receive(:database).and_return(db)
    allow(db).to receive(:command).with(hello: 1).and_return(double(documents: [hello]))
    session = double("session", start_transaction: nil, abort_transaction: nil, end_session: nil)
    allow(client).to receive(:start_session).and_return(session)
    instance_double(Monq::Environment, client: client, name: name, sandbox?: false).tap do |e|
      allow(e).to receive(:bind_session)
      allow(e).to receive(:clear_session)
    end
  end

  it "does not start a session when any environment is standalone" do
    good = sandbox_env({ "ok" => 1, "setName" => "rs0" })
    bad = sandbox_env({ "ok" => 1 }, name: "ops")
    expect(good.client).not_to receive(:start_session)
    expect(bad.client).not_to receive(:start_session)
    expect { described_class.enter([good, bad]) }.to raise_error(Monq::Error, /replica set|mongos/i)
  end

  it "starts a session on each client when all support transactions" do
    good = sandbox_env({ "ok" => 1, "setName" => "rs0" })
    expect(good.client).to receive(:start_session).and_return(double(start_transaction: nil, abort_transaction: nil, end_session: nil))
    described_class.enter([good])
    expect(good).to have_received(:bind_session)
  end
end
