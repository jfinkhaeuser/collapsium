require 'spec_helper'
require_relative '../lib/collapsium/uber_hash'

describe Collapsium::UberHash do
  it "has recursive_merge support" do
    x = ::Collapsium::UberHash.new(foo: [1])

    # Interface expecations
    expect(x.respond_to?(:recursive_merge)).to be_truthy
    expect(x.respond_to?(:recursive_merge!)).to be_truthy

    # Behaviour expectations
    x.recursive_merge!(foo: [2])
    expect(x[:foo].length).to eql 2
  end

  it "has pathed access" do
    x = ::Collapsium::UberHash.new(
      "foo" => {
        "bar" => 42,
      }
    )

    # Interface expecations
    expect(x.respond_to?(:separator)).to be_truthy
    expect(x.respond_to?(:split_pattern)).to be_truthy

    # Behaviour expectations
    expect(x["foo.bar"]).to eql 42
  end

  it "has indifferent access" do
    x = ::Collapsium::UberHash.new(foo: 42)
    expect(x['foo']).to eql 42

    x = ::Collapsium::UberHash.new('foo' => 42)
    expect(x[:foo]).to eql 42
  end

  it "can be initialized without arguments" do
    x = ::Collapsium::UberHash.new
    expect(x.empty?).to be_truthy
  end

  it "has recursive_dup support" do
    x = ::Collapsium::UberHash.new
    expect(x.respond_to?(:recursive_dup)).to be_truthy
    expect(x.respond_to?(:deep_dup)).to be_truthy
  end

  it "has recursive_sort support" do
    x = ::Collapsium::UberHash.new
    expect(x.respond_to?(:recursive_sort)).to be_truthy
    expect(x.respond_to?(:recursive_sort!)).to be_truthy
  end

  it "has prototype_match support" do
    x = ::Collapsium::UberHash.new
    expect(x.respond_to?(:prototype_match)).to be_truthy
  end

  it "creates an UberHash when duplicated" do
    x = ::Collapsium::UberHash.new
    y = x.dup
    expect(y.is_a?(::Collapsium::UberHash)).to be_truthy
  end

  it "creates nested UberHashes from a nested Hash input" do
    data = {
      some: {
        nested: true,
      }
    }
    x = ::Collapsium::UberHash.new(data)
    expect(x[:some].is_a?(::Collapsium::UberHash)).to be_truthy
  end

  it "behaves like a Hash" do
    tester = ::Collapsium::UberHash.new
    expect { tester[] }.to raise_error(ArgumentError)
  end
end
