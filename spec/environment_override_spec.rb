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
    ENV.delete("FOO")
    ENV.delete("BAR")
  end

  context "environment variable name" do
    it "upcases keys" do
      expect(::Collapsium::EnvironmentOverride.key_to_env("foo")).to eql "FOO"
      expect(::Collapsium::EnvironmentOverride.key_to_env("f0o")).to eql "F0O"
    end

    it "replaces non-alphanumeric characters with underscores" do
      expect(::Collapsium::EnvironmentOverride.key_to_env("foo!bar")).to \
        eql "FOO_BAR"
      expect(::Collapsium::EnvironmentOverride.key_to_env("foo.bar")).to \
        eql "FOO_BAR"
      expect(::Collapsium::EnvironmentOverride.key_to_env("foo@bar")).to \
        eql "FOO_BAR"
    end

    it "collapses multiple underscores into one" do
      expect(::Collapsium::EnvironmentOverride.key_to_env("foo!_@bar")).to \
        eql "FOO_BAR"
    end

    it "strips leading and trailing underscores" do
      expect(::Collapsium::EnvironmentOverride.key_to_env(".foo@bar")).to \
        eql "FOO_BAR"
      expect(::Collapsium::EnvironmentOverride.key_to_env("foo@bar_")).to \
        eql "FOO_BAR"
    end
  end

  context "without PathedAccess" do
    it "overrides first-order keys" do
      expect(@tester["foo"].is_a?(Hash)).to be_truthy
      ENV["FOO"] = "test"
      expect(@tester["foo"].is_a?(Hash)).to be_falsy
      expect(@tester["foo"]).to eql "test"
    end

    it "inherits environment override" do
      expect(@tester["foo"]["bar"].is_a?(Integer)).to be_truthy
      ENV["BAR"] = "test"
      expect(@tester["foo"]["bar"].is_a?(Integer)).to be_falsy
      expect(@tester["foo"]["bar"]).to eql "test"
    end

    it "write still works" do
      @tester.store("foo", 42)
      expect(@tester["foo"]).to eql 42
    end

    it "changes with every env change" do
      ENV["BAR"] = "test1"
      expect(@tester["foo"]["bar"]).to eql "test1"
      ENV["BAR"] = "test2"
      expect(@tester["foo"]["bar"]).to eql "test2"
    end

    it "resets when the env resets" do
      ENV["BAR"] = "test"
      expect(@tester["foo"]["bar"]).to eql "test"
      ENV.delete("BAR")
      expect(@tester["foo"]["bar"]).to eql 42
    end
  end

  context "with PathedAccess" do
    before :each do
      @tester = {
        "foo" => {
          "bar" => 42
        },
        "baz" => [{ "quux" => 123 }]
      }
      @tester.extend(::Collapsium::PathedAccess)
      @tester.extend(::Collapsium::EnvironmentOverride)
      ENV.delete("FOO")
      ENV.delete("BAR")
      ENV.delete("FOO_BAR")
      ENV.delete("BAZ_0_QUUX")
    end

    it "overrides first-order keys" do
      expect(@tester["foo"].is_a?(Hash)).to be_truthy
      ENV["FOO"] = "test"
      expect(@tester["foo"].is_a?(Hash)).to be_falsy
      expect(@tester["foo"]).to eql "test"
    end

    it "inherits environment override" do
      expect(@tester["foo.bar"].is_a?(Integer)).to be_truthy
      ENV["BAR"] = "test"
      expect(@tester["foo.bar"].is_a?(Integer)).to be_falsy
      expect(@tester["foo.bar"]).to eql "test"
    end

    it "write still works" do
      @tester.store("foo", 42)
      expect(@tester["foo"]).to eql 42
    end

    it "changes with every env change" do
      ENV["BAR"] = "test1"
      expect(@tester["foo.bar"]).to eql "test1"
      ENV["BAR"] = "test2"
      expect(@tester["foo.bar"]).to eql "test2"
    end

    it "resets when the env resets" do
      ENV["BAR"] = "test"
      expect(@tester["foo.bar"]).to eql "test"
      ENV.delete("BAR")
      expect(@tester["foo.bar"]).to eql 42
    end

    it "overrides from pathed key" do
      expect(@tester["foo.bar"].is_a?(Integer)).to be_truthy
      ENV["FOO_BAR"] = "test"
      expect(@tester["foo.bar"].is_a?(Integer)).to be_falsy
      expect(@tester["foo.bar"]).to eql "test"
    end

    it "prefers pathed key over non-pathed key" do
      expect(@tester["foo.bar"].is_a?(Integer)).to be_truthy
      ENV["FOO_BAR"] = "pathed"
      ENV["BAR"] = "simple"
      expect(@tester["foo.bar"].is_a?(Integer)).to be_falsy
      expect(@tester["foo.bar"]).to eql "pathed"
    end

    it "prefers pathed key over non-pathed key when using nested values" do
      expect(@tester["foo"]["bar"].is_a?(Integer)).to be_truthy
      ENV["FOO_BAR"] = "pathed"
      ENV["BAR"] = "simple"
      expect(@tester["foo"]["bar"].is_a?(Integer)).to be_falsy
      expect(@tester["foo"]["bar"]).to eql "pathed"
    end

    it "can deal with componentized keys" do
      expect(@tester["foo"]["foo.bar"]).to be_nil
      ENV["FOO_BAR"] = "pathed"
      expect(@tester["foo"]["foo.bar"]).to be_nil
    end

    it "works with arrays" do
      expect(@tester["baz"][0]["quux"]).to eql 123
      ENV["BAZ_0_QUUX"] = "override"
      expect(@tester["baz"][0]["quux"]).to eql "override"
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

  context "JSON" do
    it "interprets JSON content in environment variables" do
      ENV["FOO"] = '{ "json_key": "json_value" }'
      expect(@tester["foo"].is_a?(Hash)).to be_truthy
      expect(@tester["foo"]["json_key"]).to eql "json_value"
    end

    it "respects PathedAccess" do
      @tester = { "foo" => { "bar" => 42 } }
      @tester.extend(::Collapsium::PathedAccess)
      @tester.extend(::Collapsium::EnvironmentOverride)

      ENV["FOO_BAR"] = '{ "json_key": "json_value" }'
      expect(@tester["foo.bar"].is_a?(Hash)).to be_truthy
      expect(@tester["foo.bar"]["json_key"]).to eql "json_value"
      expect(@tester["foo"]["bar.json_key"]).to eql "json_value"
    end
  end

  context "coverage" do
    it "raises when not passing arguments" do
      expect { @tester.fetch }.to raise_error(ArgumentError)
    end
  end
end
