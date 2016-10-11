require 'spec_helper'
require_relative '../lib/collapsium/support/path_components'

describe ::Collapsium::Support::PathComponents do
  let(:tester) { Class.new { extend ::Collapsium::Support::PathComponents } }

  context "#separator" do
    it "defaults to DEFAULT_SEPARATOR" do
      expect(tester.separator).to eql ::Collapsium::Support::PathComponents::DEFAULT_SEPARATOR
    end

    it "can be set" do
      expect { tester.separator = ':' }.not_to raise_error
      expect(tester.separator).to eql ':'

      tester.separator = ::Collapsium::Support::PathComponents::DEFAULT_SEPARATOR
    end
  end

  context "#path_prefix" do
    it "defaults to an empty string" do
      expect(tester.path_prefix).to eql ''
    end

    it "can be set, but normalizes its value" do
      expect { tester.path_prefix = 'foo' }.not_to raise_error
      expect(tester.path_prefix).to eql '.foo'  # DEFAULT_SEPARATOR

      tester.path_prefix = ''
    end
  end

  context "#path_components" do
    it "splits a path into components" do
      expect(tester.path_components("foo.bar")).to eql %w(foo bar)
    end

    it "strips empty components at the beginning" do
      expect(tester.path_components("..foo.bar")).to eql %w(foo bar)
    end

    it "strips empty components at the end" do
      expect(tester.path_components("foo.bar..")).to eql %w(foo bar)
    end

    it "strips empty components in the middle" do
      expect(tester.path_components("foo...bar")).to eql %w(foo bar)
    end
  end

  context "#join_path" do
    it "joins path components" do
      expect(tester.join_path(%w(foo bar))).to eql "foo.bar"
    end

    it "joins empty components to an empty string" do
      expect(tester.join_path([])).to eql ""
    end
  end

  context "#normalize_path" do
    it "normalizes a path" do
      expect(tester.normalize_path("foo..bar..baz.")).to eql ".foo.bar.baz"
    end

    it "normalizes an array path" do
      expect(tester.normalize_path(['foo', '', 'bar'])).to eql ".foo.bar"
    end
  end
end
