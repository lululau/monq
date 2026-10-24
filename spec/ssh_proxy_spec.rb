# frozen_string_literal: true

RSpec.describe Monq::SSHProxy do
  it "returns the local host and port" do
    gateway = instance_double(Net::SSH::Gateway, open: 27018, shutdown!: nil, active?: true)
    allow(Net::SSH::Gateway).to receive(:new).and_return(gateway)
    proxy = described_class.new(host: "jump", user: "deploy", port: 22, forward_host: "10.0.0.12", forward_port: 27017, local_port: 27018)
    expect(proxy.database_host_port).to eq(host: "127.0.0.1", port: 27018)
  end

  it "reconnects only when inactive" do
    gateway = instance_double(Net::SSH::Gateway, open: 27018, shutdown!: nil, active?: true)
    allow(Net::SSH::Gateway).to receive(:new).and_return(gateway)
    proxy = described_class.new(host: "jump", user: "deploy", forward_host: "10.0.0.12", forward_port: 27017)
    expect(proxy).not_to receive(:reconnect!)
    proxy.reconnect
  end
end
