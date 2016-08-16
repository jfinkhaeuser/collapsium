require 'spec_helper'
require_relative '../lib/collapsium/pathed_access'

class PathedHash < Hash
  prepend ::Collapsium::PathedAccess
end

describe ::Collapsium::PathedAccess do
  before :each do
    @tester = {}
    @tester.extend(::Collapsium::PathedAccess)
  end

  describe "Path components" do
    it "splits a path into components" do
      expect(@tester.path_components("foo.bar")).to eql %w(foo bar)
    end

    it "strips empty components at the beginning" do
      expect(@tester.path_components("..foo.bar")).to eql %w(foo bar)
    end

    it "strips empty components at the end" do
      expect(@tester.path_components("foo.bar..")).to eql %w(foo bar)
    end

    it "strips empty components in the middle" do
      expect(@tester.path_components("foo...bar")).to eql %w(foo bar)
    end

    it "joins path components" do
      expect(@tester.join_path(%w(foo bar))).to eql "foo.bar"
    end

    it "joins empty components to an empty string" do
      expect(@tester.join_path([])).to eql ""
    end

    it "normalizes a path" do
      expect(@tester.normalize_path("foo..bar..baz.")).to eql ".foo.bar.baz"
    end
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
    context ":path_prefix" do
      it "can be read" do
        expect { @tester.path_prefix }.not_to raise_error
      end

      it "defaults to empty String" do
        expect(@tester.path_prefix).to be_empty
        expect(@tester.path_prefix.class).to eql String
      end

      it "can be set" do
        expect { @tester.path_prefix = "foo.bar" }.not_to raise_error
      end

      it "normalizes when set" do
        @tester.path_prefix = "foo..bar..baz.."
        expect(@tester.path_prefix).to eql ".foo.bar.baz"
      end
    end

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

  describe "nested inherit capabilities" do
    before do
      @tester['foo'] = {
        'bar' => {
          'baz' => 42,
        },
      }
    end

    it "can still perform pathed access" do
      foo = @tester['foo']
      expect(foo['bar.baz']).to eql 42
    end

    it "knows its path prefix" do
      bar = @tester['foo.bar']
      expect(bar.path_prefix).to eql '.foo.bar'
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

  context PathedHash do
    let(:test_hash) { PathedHash.new }

    it "can write recursively" do
      test_hash["foo.bar"] = 42
      expect(test_hash["foo.bar"]).to eql 42
    end
  end
end
