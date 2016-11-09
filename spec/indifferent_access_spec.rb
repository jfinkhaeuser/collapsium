require 'spec_helper'
require_relative '../lib/collapsium/indifferent_access'

describe ::Collapsium::IndifferentAccess do
  let(:tester) do
    tester = {}
    tester.default_proc = ::Collapsium::IndifferentAccess::DEFAULT_PROC
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

  it "still works with other keys" do
    expect(tester).to be_empty

    tester[42] = "foo"
    expect(tester[42]).to eql "foo"
  end
end
