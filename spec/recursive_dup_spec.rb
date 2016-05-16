require 'spec_helper'
require_relative '../lib/collapsium/recursive_dup'

describe ::Collapsium::RecursiveDup do
  it "duplicates nested values" do
    h = {
      'a' => 1,
      :c => {
        'd' => 4,
        'f' => 6,
        42 => 5,
      },
      'b' => 2,
    }
    h.extend(::Collapsium::RecursiveDup)

    h2 = h.deep_dup

    expect(h2.object_id).not_to eql h.object_id
    expect(h2[:c].object_id).not_to eql h[:c].object_id
  end
end
