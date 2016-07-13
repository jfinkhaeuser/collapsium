require 'spec_helper'
require_relative '../lib/collapsium/pathed_access'

describe ::Collapsium::PathedAccess do
  before :each do
    @tester = {}
    @tester.extend(::Collapsium::PathedAccess)
  end

  describe "Hash-like" do
    it "responds to Hash functions" do
      [:invert, :delete, :fetch].each do |meth|
        expect(@tester.respond_to?(meth)).to eql true
      end
    end

    it "can be used like a Hash" do
      @tester[:foo] = 42
      inverted = @tester.invert
      expect(inverted.empty?).to eql false
      expect(inverted[42]).to eql :foo
    end

    it "delegates to Hash if it's nothing to do with paths" do
      expect(@tester.default).to be_nil
    end
  end

  describe "pathed access" do
    it "can recursively read entries via a path" do
      @tester["foo"] = 42
      @tester["bar"] = {
        "baz" => "quux",
        "blah" => [1, 2],
      }

      expect(@tester["foo"]).to eql 42
      expect(@tester["bar.baz"]).to eql "quux"
      expect(@tester["bar.blah"]).to eql [1, 2]

      expect(@tester["nope"]).to eql nil
      expect(@tester["bar.nope"]).to eql nil
    end

    it "behaves consistently if in a path the first node cannot be found" do
      @tester["foo"] = 42

      expect(@tester["nope.bar"]).to eql nil
    end

    it "treats a single separator as the root" do
      @tester["foo"] = 42

      expect(@tester[@tester.separator]["foo"]).to eql 42
    end

    it "treats an empty path as the root" do
      @tester["foo"] = 42

      expect(@tester[""]["foo"]).to eql 42
    end

    it "can recursively write entries via a path" do
      @tester["foo.bar"] = 42
      expect(@tester["foo.bar"]).to eql 42
    end

    it "understands absolute paths (starting with separator)" do
      @tester["foo"] = 42
      @tester["bar"] = {
        "baz" => "quux",
        "blah" => [1, 2],
      }

      expect(@tester["bar.baz"]).to eql "quux"
      expect(@tester[".bar.baz"]).to eql "quux"
    end

    it "behaves like a hash if a child node does not exist" do
      expect(@tester["asdf"]).to be_nil
      expect(@tester.fetch("asdf", 42)).to eql 42
      expect(@tester[".does.not.exist"]).to be_nil
      expect(@tester.fetch(".does.not.exist", 42)).to eql 42
    end
  end

  describe "with indifferent access" do
    before do
      require_relative '../lib/collapsium/indifferent_access'
    end

    it "can write with indifferent access without overwriting" do
      @tester[:foo] = {
        bar: 42,
        baz: 'quux',
      }
      @tester.default_proc = ::Collapsium::IndifferentAccess::DEFAULT_PROC

      expect(@tester['foo.bar']).to eql 42
      expect(@tester['foo.baz']).to eql 'quux'

      @tester['foo.bar'] = 123
      expect(@tester['foo.bar']).to eql 123
      expect(@tester['foo.baz']).to eql 'quux'
    end
  end
end
