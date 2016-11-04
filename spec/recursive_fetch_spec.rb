require 'spec_helper'
require_relative '../lib/collapsium/recursive_fetch'

describe ::Collapsium::RecursiveFetch do
  let(:tester) do
    h = {
      "foo" => 42,
      "bar" => 123,
      "baz" => {
        "foo" => 321,
        "unique" => "something"
      }
    }
    h.extend(::Collapsium::RecursiveFetch)
  end

  context "fetching basics" do
    it ":fetch_one fetches the first value found" do
      expect(tester.recursive_fetch_one("foo")).to eql 42
      expect(tester.recursive_fetch_one("unique")).to eql "something"
    end

    it ":fetch fetches all values" do
      expect(tester.recursive_fetch("foo")).to eql [42, 321]
    end
  end

  context "defaults" do
    it "uses nil by default" do
      expect(tester.recursive_fetch_one('does not exist')).to be_nil
      expect(tester.recursive_fetch('does not exist')).to be_nil
    end

    it "uses a given value" do
      expect(tester.recursive_fetch_one('does not exist', 42)).to eql 42
      expect(tester.recursive_fetch('does not exist', 42)).to eql 42
    end
  end

  context "blocks" do
    it ":fetch_one invokes the block once" do
      called = 0
      tester.recursive_fetch_one('foo') do |parent, result, default|
        expect(parent['foo']).to eql 42
        expect(result).to eql 42
        expect(default).to be_nil
        called += 1
      end

      expect(called).to eql 1
    end

    it ":fetch invokes the block twice" do
      called = 0
      tester.recursive_fetch('foo') do |parent, result, default|
        expect(parent['foo'].is_a?(Integer)).to be_truthy
        expect(result.is_a?(Integer)).to be_truthy
        expect(default).to be_nil
        called += 1
      end

      expect(called).to eql 2
    end

    it "can alter the value" do
      called = 0
      ret = tester.recursive_fetch_one('foo') do |parent, result, default|
        expect(parent['foo']).to eql 42
        expect(result).to eql 42
        expect(default).to be_nil
        called += 1

        next "new value"
      end

      expect(called).to eql 1
      expect(ret).to eql "new value"
    end
  end
end
