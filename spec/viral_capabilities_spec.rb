require 'spec_helper'
require_relative '../lib/collapsium/viral_capabilities'

module TestModule
  extend ::Collapsium::ViralCapabilities

  def find_me; end
end # TestModule

class PrependedHash < Hash
  prepend TestModule
end

class IncludedHash < Hash
  include TestModule
end

class ExtendedHash < Hash
  extend TestModule
end

class IncludedArray < Array
  include TestModule
end

class DirectPrependedHash < Hash
  prepend ::Collapsium::ViralCapabilities

  def find_me; end
end

class DirectIncludedHash < Hash
  include ::Collapsium::ViralCapabilities

  def find_me; end
end

class DirectExtendedHash < Hash
  extend ::Collapsium::ViralCapabilities

  def find_me; end
end

class LoggingHash < Hash
  include ::Collapsium::Support::HashMethods
  class << self
    include ::Collapsium::Support::Methods
  end

  attr_accessor :each_called

  # Overwrite :each method, so that it remembers when it's been called. This is
  # based on the knowledge that the module's way of enhancing Hash values calls
  # :each on parameters, i.e. that the :merge! call in the test case below ends
  # calling :each.
  # Or rather, it should. The test case checks whether it does.
  wrap_method(self, :each) do |super_method, *args, &block|
    @each_called ||= 0
    @each_called += 1
    result = super_method.call(*args, &block)
    result.each_called = @each_called
    next result
  end
end

module ViralityModule
  extend ::Collapsium::ViralCapabilities
  include ::Collapsium::Support::Methods

  def virality(value, *_)
    # Wrap :delete to become a no-op
    wrap_method(value, :delete) do
      next true
    end
    return value
  end
end

class RespondsToHashAncestor < Hash
  def hash_ancestor
    return nil
  end
end

describe ::Collapsium::ViralCapabilities do
  context PrependedHash do
    let(:tester) do
      x = PrependedHash.new
      x.merge!(foo: { bar: [{ baz: true }] })
    end

    before do
      expect(tester.respond_to?(:find_me)).to be_truthy
    end

    it "replicates itself" do
      expect(tester[:foo].respond_to?(:find_me)).to be_truthy
      expect(tester[:foo][:bar][0].respond_to?(:find_me)).to be_truthy
      expect(tester[:foo][:bar][0].class).to eql PrependedHash
    end
  end

  context IncludedHash do
    let(:tester) do
      x = IncludedHash.new
      x.merge!(foo: { bar: [{ baz: true }] })
    end

    before do
      expect(tester.respond_to?(:find_me)).to be_truthy
    end

    it "replicates itself" do
      expect(tester[:foo].respond_to?(:find_me)).to be_truthy
      expect(tester[:foo][:bar][0].respond_to?(:find_me)).to be_truthy
      expect(tester[:foo][:bar][0].class).to eql IncludedHash
    end
  end

  context IncludedArray do
    let(:tester) do
      x = IncludedArray.new
      x << { foo: { bar: [{ baz: true }, 42] } }
    end

    before do
      expect(tester.respond_to?(:find_me)).to be_truthy
    end

    it "replicates itself" do
      expect(tester[0][:foo].respond_to?(:find_me)).to be_truthy
      expect(tester[0][:foo][:bar][0].respond_to?(:find_me)).to be_truthy
      expect(tester[0][:foo][:bar].class).to eql IncludedArray
    end
  end

  context ExtendedHash do
    let(:tester) do
      x = ExtendedHash.new
      x.merge!(foo: { bar: [{ baz: true }] })
    end

    it "does not receive viral capabilities" do
      expect(tester.respond_to?(:find_me)).to be_falsy
    end
  end

  context DirectPrependedHash do
    let(:tester) do
      x = DirectPrependedHash.new
      x.merge!(foo: { bar: [{ baz: true }] })
    end

    before do
      expect(tester.respond_to?(:find_me)).to be_truthy
    end

    it "replicates itself" do
      expect(tester[:foo].respond_to?(:find_me)).to be_truthy
    end
  end

  context DirectIncludedHash do
    let(:tester) do
      x = DirectIncludedHash.new
      x.merge!(foo: { bar: [{ baz: true }] })
    end

    before do
      expect(tester.respond_to?(:find_me)).to be_truthy
    end

    it "replicates itself" do
      expect(tester[:foo].respond_to?(:find_me)).to be_truthy
      expect(tester[:foo][:bar][0].respond_to?(:find_me)).to be_truthy
    end
  end

  context DirectExtendedHash do
    let(:tester) do
      x = DirectExtendedHash.new
      x.merge!(foo: { bar: [{ baz: true }] })
    end

    before do
      expect(tester.respond_to?(:find_me)).to be_truthy
    end

    it "replicates itself" do
      expect(tester[:foo].respond_to?(:find_me)).to be_truthy
      expect(tester[:foo][:bar][0].respond_to?(:find_me)).to be_truthy
    end
  end

  context "writing" do
    let(:tester) { DirectExtendedHash.new }

    it "enhances values when writing" do
      data = LoggingHash.new
      # rubocop:disable Performance/RedundantMerge
      data.merge!(bar: true)
      # rubocop:enable Performance/RedundantMerge

      # This calls a write method ([]=) and should call :each on data.
      tester[:foo] = data
      expect(data.each_called).to eql 1
    end
  end

  context "non-class based enhancements" do
    let(:tester) do
      x = {}
      x.extend(TestModule)
      x.merge!(foo: { bar: [{ baz: { quux: true } }] })
    end

    before do
      expect(tester.respond_to?(:find_me)).to be_truthy
    end

    it "replicates itself" do
      expect(tester[:foo].respond_to?(:find_me)).to be_truthy
      expect(tester[:foo][:bar][0][:baz].respond_to?(:find_me)).to be_truthy
    end
  end

  context ViralityModule do
    let(:tester) do
      x = {}
      x.extend(ViralityModule)
      x.merge!(foo: { bar: [{ baz: true }] })
    end

    before do
      expect(tester.respond_to?(:virality)).to be_truthy
    end

    it "replicates itself" do
      # Just check that the module went viral; it doesn't check the viral
      # enhancements work.
      expect(tester[:foo].respond_to?(:virality)).to be_truthy
      expect(tester[:foo][:bar][0].respond_to?(:virality)).to be_truthy

      # Now also check the viral enhancements. In this case, :delete becomes a
      # no-op.
      expect(tester.delete(:foo)).to be_truthy
      expect(tester[:foo]).not_to be_nil
      expect(tester[:foo].delete(:bar)).to be_truthy
      expect(tester[:foo][:bar]).not_to be_nil
    end
  end

  context "values already of the same class" do
    # rubocop:disable Performance/RedundantMerge
    let(:innermost) do
      innermost = PrependedHash.new
      innermost.merge!(quux: true)
      innermost
    end

    let(:inner) do
      inner = {}
      inner.merge!(foo: true, bar: innermost)
      inner
    end

    let(:tester) do
      PrependedHash.new
    end
    # rubocop:enable Performance/RedundantMerge

    it "peforms a no-op when adding the right class" do
      tester[:bar] = inner
      expect(tester[:bar][:bar].object_id).to eql innermost.object_id
    end
  end

  context RespondsToHashAncestor do
    it "can still be used virally" do
      tester = PrependedHash.new
      expect { tester.merge(RespondsToHashAncestor.new) }.not_to raise_error
    end
  end
end
