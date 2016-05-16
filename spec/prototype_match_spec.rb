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

  it "matches a prototype containing any individual key (non-strict)" do
    # Keys exist in hash
    expect(@hash.prototype_match('a' => nil)).to be_truthy
    expect(@hash.prototype_match('b' => nil)).to be_truthy
    expect(@hash.prototype_match(c: nil)).to be_truthy

    # Key doesn't exist in hash
    expect(@hash.prototype_match(foo: nil)).to be_falsy
  end

  it "does't match a prototype containing an individual key in strict mode" do
    expect(@hash.prototype_match({ 'a' => nil }, true)).to be_falsy
  end

  it "matches nested prototypes (non-strict)" do
    proto = {
      c: {
        'd' => nil,
      }
    }
    expect(@hash.prototype_match(proto)).to be_truthy
  end

  it "doesn't match nested prototypes (strict)" do
    proto = {
      c: {
        'd' => nil,
      }
    }
    expect(@hash.prototype_match(proto, true)).to be_falsy
  end

  it "fails if a value type mismatches a prototype value's type" do
    proto = {
      c: {
        'd' => {},
      }
    }
    expect(@hash.prototype_match(proto)).to be_falsy
  end

  it "fails if a value mismatches a prototype value" do
    proto = {
      c: {
        'd' => 42,
      }
    }
    expect(@hash.prototype_match(proto)).to be_falsy
  end
end
