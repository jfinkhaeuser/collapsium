require 'spec_helper'
require_relative '../lib/collapsium/recursive_merge'

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

    to_merge = {
      foo: {
        bar: 123,     # should overwrite
        baz: ['new'], # should concatenate
        quux: {       # should merge
          another: 123,
        },
      },
    }

    x = @tester.recursive_merge(to_merge)

    expect(x[:foo][:bar]).to eql 123
    expect(x[:foo][:baz] - %w(old new)).to be_empty
    expect(x[:foo][:quux][:something]).to eql 42
    expect(x[:foo][:quux][:another]).to eql 123
  end
end
