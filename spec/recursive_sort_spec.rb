require 'spec_helper'
require_relative '../lib/collapsium/recursive_sort'

describe ::Collapsium::RecursiveSort do
  it "sorts a nested hash with string keys in place" do
    h = {
      'a' => 1,
      'c' => {
        'd' => 4,
        'f' => 6,
        'e' => 5,
      },
      'b' => 2,
    }
    h.extend(::Collapsium::RecursiveSort)

    h.recursive_sort!

    expect(h.keys).to eql %w[a b c]
    expect(h['c'].keys).to eql %w[d e f]
  end

  it "duplicates and sorts an outer hash (not deep)" do
    h = {
      'a' => 1,
      'c' => {
        'd' => 4,
        'f' => 6,
        'e' => 5,
      },
      'b' => 2,
    }
    h.extend(::Collapsium::RecursiveSort)

    h2 = h.recursive_sort

    # Only the new outer hash's keys are sorted
    expect(h.keys).to eql %w[a c b]
    expect(h2.keys).to eql %w[a b c]

    # Both inner hashes are sorted because dup isn't deep
    expect(h['c'].keys).to eql %w[d e f]
    expect(h2['c'].keys).to eql %w[d e f]

    # Similar with object IDs
    expect(h.object_id).not_to eql h2.object_id
    expect(h['c'].object_id).to eql h2['c'].object_id
  end

  it "it uses RecursiveDup if present" do
    require_relative '../lib/collapsium/recursive_dup'
    h = {
      'a' => 1,
      'c' => {
        'd' => 4,
        'f' => 6,
        'e' => 5,
      },
      'b' => 2,
    }
    h.extend(::Collapsium::RecursiveSort)
    h.extend(::Collapsium::RecursiveDup)

    h2 = h.recursive_sort

    # Only the new outer hash's keys are sorted
    expect(h.keys).to eql %w[a c b]
    expect(h2.keys).to eql %w[a b c]

    # Only the new inner hash's keys are sorted
    expect(h['c'].keys).to eql %w[d f e]
    expect(h2['c'].keys).to eql %w[d e f]

    # Similar with object IDs
    expect(h.object_id).not_to eql h2.object_id
    expect(h['c'].object_id).not_to eql h2['c'].object_id
  end

  it "works with IndifferentAccess" do
    require_relative '../lib/collapsium/indifferent_access'
    tester = {
      "foo" => 42,
      "bar" => 123,
      :foo => "foo from symbol",
      :bar => "bar from symbol",
    }
    tester.extend(::Collapsium::RecursiveSort)
    tester.extend(::Collapsium::IndifferentAccess)

    expect { tester.recursive_sort! }.not_to raise_error
  end
end
