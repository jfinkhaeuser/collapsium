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
end
