# frozen_string_literal: true

RSpec.describe "blog_dev", :integration do
  before do
    skip "set MONQ_TEST_URI and MONQ_TEST_DB" unless ENV["MONQ_TEST_URI"] && ENV["MONQ_TEST_DB"]
  end

  it "counts users" do
    klass = Class.new do
      include Mongoid::Document
      store_in collection: "users", client: :default, database: ENV.fetch("MONQ_TEST_DB")
    end
    Mongo::Client.new(ENV.fetch("MONQ_TEST_URI"), database: ENV.fetch("MONQ_TEST_DB")) do |client|
      Mongoid::Clients.set(:default, client)
      expect(klass.count).to be >= 1
    end
  end
end
