require 'spec_helper'
require_relative '../lib/collapsium/environment_override'
require_relative '../lib/collapsium/pathed_access'

class EnvironmentHash < Hash
  # We need only one of these; this is for coverage mostly
  prepend ::Collapsium::EnvironmentOverride
  include ::Collapsium::EnvironmentOverride
end

describe ::Collapsium::EnvironmentOverride do
  before :each do
    @tester = { "foo" => { "bar" => 42 } }
    @tester.extend(::Collapsium::EnvironmentOverride)
    ENV["FOO"] = nil
    ENV["BAR"] = nil
  end

  context "environment variable name" do
    it "upcases keys" do
      expect(@tester.key_to_env("foo")).to eql "FOO"
    end

    it "replaces non-alphanumeric characters with underscores" do
      expect(@tester.key_to_env("foo!bar")).to eql "FOO_BAR"
      expect(@tester.key_to_env("foo.bar")).to eql "FOO_BAR"
      expect(@tester.key_to_env("foo@bar")).to eql "FOO_BAR"
    end

    it "collapses multiple underscores into one" do
      expect(@tester.key_to_env("foo!_@bar")).to eql "FOO_BAR"
    end

    it "strips leading and trailing underscores" do
      expect(@tester.key_to_env(".foo@bar")).to eql "FOO_BAR"
      expect(@tester.key_to_env("foo@bar_")).to eql "FOO_BAR"
    end
  end

  context "without pathed access" do
    it "overrides first-order keys" do
      expect(@tester["foo"].is_a?(Hash)).to be_truthy
      ENV["FOO"] = "test"
      expect(@tester["foo"].is_a?(Hash)).to be_falsy
      expect(@tester["foo"]).to eql "test"
    end

    it "inherits environment override" do
      expect(@tester["foo"]["bar"].is_a?(Fixnum)).to be_truthy
      ENV["BAR"] = "test"
      expect(@tester["foo"]["bar"].is_a?(Fixnum)).to be_falsy
      expect(@tester["foo"]["bar"]).to eql "test"
    end

    it "write still works" do
      @tester.store("foo", 42)
      expect(@tester["foo"]).to eql 42
    end
  end

  context "with pathed access" do
    before :each do
      @tester = { "foo" => { "bar" => 42 } }
      @tester.extend(::Collapsium::EnvironmentOverride)
      @tester.extend(::Collapsium::PathedAccess)
      ENV["FOO"] = nil
      ENV["BAR"] = nil
      ENV["FOO_BAR"] = nil
    end

    it "overrides first-order keys" do
      expect(@tester["foo"].is_a?(Hash)).to be_truthy
      ENV["FOO"] = "test"
      expect(@tester["foo"].is_a?(Hash)).to be_falsy
      expect(@tester["foo"]).to eql "test"
    end

    it "inherits environment override" do
      expect(@tester["foo"]["bar"].is_a?(Fixnum)).to be_truthy
      ENV["BAR"] = "test"
      expect(@tester["foo"]["bar"].is_a?(Fixnum)).to be_falsy
      expect(@tester["foo"]["bar"]).to eql "test"
    end

    it "write still works" do
      @tester.store("foo", 42)
      expect(@tester["foo"]).to eql 42
    end

    it "overrides from pathed key" do
      expect(@tester["foo.bar"].is_a?(Fixnum)).to be_truthy
      ENV["FOO_BAR"] = "test"
      expect(@tester["foo.bar"].is_a?(Fixnum)).to be_falsy
      expect(@tester["foo.bar"]).to eql "test"
    end

    it "prefers pathed key over non-pathed key" do
      expect(@tester["foo.bar"].is_a?(Fixnum)).to be_truthy
      ENV["FOO_BAR"] = "pathed"
      ENV["BAR"] = "simple"
      expect(@tester["foo.bar"].is_a?(Fixnum)).to be_falsy
      expect(@tester["foo.bar"]).to eql "pathed"
    end

    it "prefers pathed key over non-pathed key when using nested values" do
      expect(@tester["foo"]["bar"].is_a?(Fixnum)).to be_truthy
      ENV["FOO_BAR"] = "pathed"
      ENV["BAR"] = "simple"
      expect(@tester["foo"]["bar"].is_a?(Fixnum)).to be_falsy
      expect(@tester["foo"]["bar"]).to eql "pathed"
    end
  end

  context "respects the behaviour of wrapped methods" do
    it "works with :[]" do
      ENV["FOO"] = "test"
      expect(@tester["foo"]).to eql "test"
    end

    it "works with :fetch" do
      ENV["FOO"] = "test"
      expect(@tester.fetch("foo", 1234)).to eql "test"
    end

    it "works with :key?" do
      ENV["FOO"] = "test"
      expect(@tester.key?("foo")).to eql true   # not be_truthy
      expect(@tester.key?("bar")).to eql false  # not be_falsey
    end
  end

  context EnvironmentHash do
    let(:test_hash) { EnvironmentHash.new }

    it "works when prepended" do
      ENV["FOO"] = "test"
      expect(test_hash["foo"]).to eql "test"
    end
  end
end
