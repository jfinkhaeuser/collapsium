require 'spec_helper'
require_relative '../lib/collapsium/indifferent_access'

class IncludedIndifferentHash < Hash
  include ::Collapsium::IndifferentAccess
end

class PrependedIndifferentHash < Hash
  prepend ::Collapsium::IndifferentAccess
end

class ExtendedIndifferentHash < Hash
  extend ::Collapsium::IndifferentAccess
end

describe ::Collapsium::IndifferentAccess do
  let(:tester) do
    tester = {}
    tester.extend(::Collapsium::IndifferentAccess)
    tester
  end

  it "allows accessing string keys via symbol" do
    expect(tester).to be_empty

    tester["foo"] = 42
    expect(tester["foo"]).to eql 42
    expect(tester[:foo]).to eql 42
  end

  it "allows accessing symbol keys via strings" do
    expect(tester).to be_empty

    tester[:foo] = 42
    expect(tester[:foo]).to eql 42
    expect(tester["foo"]).to eql 42
  end

  it "allows accessing integer keys with strings or symbols" do
    expect(tester).to be_empty

    tester[42] = 123
    expect(tester[:"42"]).to eql 123
    expect(tester["42"]).to eql 123
  end

  it "allows accessing string keys with integers" do
    expect(tester).to be_empty

    tester["42"] = 123
    expect(tester[:"42"]).to eql 123
    expect(tester[42]).to eql 123
  end

  it "still works with other keys" do
    expect(tester).to be_empty

    tester[42] = "foo"

    expect(tester[nil]).to be_nil
    expect(tester[3.14]).to be_nil
  end

  it "makes keys unique" do
    test = [
      "foo", :foo,
      "42", :"42", 42,
    ]
    expect(::Collapsium::IndifferentAccess.unique_keys(test)).to eql %w(foo 42)
  end

  it "can sort keys" do
    test = [
      "foo", :foo,
      "bar", :bar,
      "42", :"42", 42,
    ]
    expecation = [
      42,
      :"42", :bar, :foo,
      "42", "bar", "foo",
    ]
    expect(::Collapsium::IndifferentAccess.sorted_keys(test)).to eql expecation
  end

  it "does nothing for Arrays" do
    test = [42]
    test.extend(::Collapsium::IndifferentAccess)

    result = nil
    expect { result = test.include?(42) }.not_to raise_error
    expect(result).to be_truthy
  end

  context IncludedIndifferentHash do
    let(:tester) { IncludedIndifferentHash.new }

    it "can be accessed indifferently" do
      tester["foo"] = 42
      expect(tester[:foo]).to eql 42
    end
  end

  context ExtendedIndifferentHash do
    let(:tester) { ExtendedIndifferentHash.new }

    it "can be accessed indifferently" do
      tester["foo"] = 42
      expect(tester[:foo]).to eql 42
    end
  end

  context PrependedIndifferentHash do
    let(:tester) { PrependedIndifferentHash.new }

    it "can be accessed indifferently" do
      tester["foo"] = 42
      expect(tester[:foo]).to eql 42
    end
  end
end
