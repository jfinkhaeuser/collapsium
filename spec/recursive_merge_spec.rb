require 'spec_helper'
require_relative '../lib/collapsium/recursive_merge'
require_relative '../lib/collapsium/indifferent_access'

describe ::Collapsium::RecursiveMerge do
  before :each do
    @tester = {}
    @tester.extend(::Collapsium::RecursiveMerge)
  end

  it "handles a nil parameter well" do
    x = @tester.recursive_merge(nil)

    expect(x.is_a?(Hash)).to be_truthy
    expect(x).to be_empty
  end

  it "merges simple values by overwriting by default" do
    @tester[:foo] = 'old'
    x = @tester.recursive_merge(foo: 'new')

    expect(x[:foo]).to eql 'new'
  end

  it "merges simple values by using the old value if requested" do
    @tester[:foo] = 'old'
    x = @tester.recursive_merge({ foo: 'new' }, false)

    expect(x[:foo]).to eql 'old'
  end

  it "merges arrays by concatenation" do
    @tester[:foo] = ['old']
    x = @tester.recursive_merge(foo: ['new'])

    expect(x[:foo].length).to eql 2
    expect(x[:foo][0]).to eql 'old'
    expect(x[:foo][1]).to eql 'new'
  end

  it "merges objects by recursing" do
    @tester[:foo] = {
      bar: 42,
      baz: ['old'],
      quux: {
        something: 42,
      }
    }
    @tester[:bar] = [1]

    to_merge = {
      foo: {
        bar: 123,     # should overwrite
        baz: ['new'], # should concatenate
        quux: {       # should merge
          another: 123,
        },
      },
      bar: [2],
    }

    x = @tester.recursive_merge(to_merge)

    expect(x[:foo][:bar]).to eql 123
    expect(x[:foo][:baz].length).to eql 2
    expect(x[:foo][:quux][:something]).to eql 42
    expect(x[:foo][:quux][:another]).to eql 123

    expect(x[:bar].length).to eql 2
  end

  it "makes nested hashes able to merge recursively" do
    @tester[:foo] = {
      bar: true,
    }
    expect(@tester[:foo].respond_to?(:recursive_merge)).to be_truthy

    to_merge = {
      foo: {
        bar: false,
      },
    }
    x = @tester.recursive_merge(to_merge)

    expect(@tester[:foo].respond_to?(:recursive_merge)).to be_truthy
    expect(x[:foo].respond_to?(:recursive_merge)).to be_truthy
  end

  context "IndifferentAccess" do
    let(:tester) do
      tester = {}
      tester.default_proc = ::Collapsium::IndifferentAccess::DEFAULT_PROC
      tester.extend(::Collapsium::RecursiveMerge)
    end

    it "merges string and symbol keys" do
      tester[:foo] = {
        bar: 123,
      }
      tester[:arr] = [2]
      other = {
        "foo" => {
          "baz asdf" => "quux",
          "bar" => 42
        },
        "arr" => [1],
      }
      x = tester.recursive_merge(other)

      expect(x.length).to eql 2
      expect(x[:foo].length).to eql 2
      expect(x[:foo]['baz asdf']).to eql 'quux'
      expect(x[:foo][:bar]).to eql 42 # overwrite
      expect(x[:arr].length).to eql 2
      expect(x[:arr]).to eql [2, 1]
    end

    it "merges string and symbol keys without overwriting" do
      tester[:foo] = {
        bar: 123,
      }
      tester[:arr] = [2]
      other = {
        "foo" => {
          "baz asdf" => "quux",
          "bar" => 42
        },
        "arr" => [1],
      }
      x = tester.recursive_merge(other, false)

      expect(x.length).to eql 2
      expect(x[:foo].length).to eql 2
      expect(x[:foo]['baz asdf']).to eql 'quux'
      expect(x[:foo][:bar]).to eql 123 # no overwrite
      expect(x[:arr].length).to eql 2
      expect(x[:arr]).to eql [2, 1]
    end
  end
end
