require 'spec_helper'
require_relative '../lib/collapsium/prototype_match'

describe ::Collapsium::PrototypeMatch do
  before :each do
    @hash = {
      'a' => 1,
      :c => {
        'd' => 4,
        'f' => 6,
        42 => 5,
      },
      'b' => 2,
    }
    @hash.extend(::Collapsium::PrototypeMatch)
  end

  it "scores positively a prototype containing any individual key (non-strict)" do
    # Keys exist in hash
    expect(@hash.prototype_match_score('a' => nil)).to be > 0
    expect(@hash.prototype_match_score('b' => nil)).to be > 0
    expect(@hash.prototype_match_score(c: nil)).to be > 0

    # Key doesn't exist in hash
    expect(@hash.prototype_match_score(foo: nil)).to be <= 0
  end

  it "scores negatively a prototype containing an individual key in strict mode" do
    expect(@hash.prototype_match_score({ 'a' => nil }, true)).to be <= 0
  end

  it "scores positively nested prototypes (non-strict)" do
    proto = {
      c: {
        'd' => nil,
      }
    }
    expect(@hash.prototype_match_score(proto)).to be > 0
  end

  it "scores negatively nested prototypes (strict)" do
    proto = {
      c: {
        'd' => nil,
      }
    }
    expect(@hash.prototype_match_score(proto, true)).to be <= 0
  end

  it "fails if a value type mismatches a prototype value's type" do
    proto = {
      c: {
        'd' => {},
      }
    }
    expect(@hash.prototype_match_score(proto)).to be <= 0
  end

  it "fails if a value mismatches a prototype value" do
    proto = {
      c: {
        'd' => 42,
      }
    }
    expect(@hash.prototype_match_score(proto)).to be <= 0
  end

  it "succeeds if a value matches a prototype value" do
    proto = {
      c: {
        'd' => 4,
      }
    }
    expect(@hash.prototype_match_score(proto)).to be > 0
  end

  it "matches prototypes" do
    # Keys exist in hash
    expect(@hash.prototype_match('a' => nil)).to be_truthy
    expect(@hash.prototype_match('b' => nil)).to be_truthy
    expect(@hash.prototype_match(c: nil)).to be_truthy

    # Key doesn't exist in hash
    expect(@hash.prototype_match(foo: nil)).to be_falsey
  end
end
