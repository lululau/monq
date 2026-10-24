# frozen_string_literal: true

RSpec.describe Monq do
  it "has a version" do
    expect(Monq::VERSION).to match(/\A\d+\.\d+\.\d+\z/)
  end

  it "defines Error" do
    expect(Monq::Error.new("nope").message).to eq("nope")
  end
end
