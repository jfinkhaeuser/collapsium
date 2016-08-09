require 'spec_helper'
require_relative '../lib/collapsium/support/methods'

module First
  class << self
    include ::Collapsium::Support::Methods

    def prepended(base)
      wrap_method(base, :calling_test) do |super_method, *args, &block|
        result = super_method.call(*args, &block)
        next "first: #{result}"
      end

      wrap_method(base, :test) do
        next "first"
      end
    end
  end # class << self
end # module First

module Second
  class << self
    include ::Collapsium::Support::Methods

    def prepended(base)
      wrap_method(base, :calling_test) do |super_method, *args, &block|
        result = super_method.call(*args, &block)
        next "second: #{result}"
      end

      wrap_method(base, :test) do
        next "second"
      end
    end
  end # class << self
end # module First

class FirstThenSecond
  def calling_test
    return "first_then_second"
  end

  def test
    return "first_then_second"
  end

  prepend First
  prepend Second
end

class SecondThenFirst
  def calling_test
    return "second_then_first"
  end

  def test
    return "second_then_first"
  end

  prepend Second
  prepend First
end

module IncludeModule
  class << self
    include ::Collapsium::Support::Methods

    def included(base)
      wrap_method(base, :calling_test) do |super_method, *args, &block|
        result = super_method.call(*args, &block)
        next "include_module: #{result}"
      end

      wrap_method(base, :test) do
        next "include_module"
      end
    end
  end
end

class Included
  def calling_test
    return "included"
  end

  def test
    return "included"
  end

  include IncludeModule
end

module NestModule
  def calling_test
    return "nest_module"
  end

  def test
    return "nest_module"
  end

  include IncludeModule
end

class PrependNested
  prepend NestModule
end

class IncludeNested
  include NestModule
end

class IncludeNestedWithOwn
  def calling_test
    return "include_nested_with_own"
  end

  def test
    return "include_nested_with_own"
  end

  include NestModule
end

class PrependNestedWithOwn
  def calling_test
    return "prepend_nested_with_own"
  end

  def test
    return "prepend_nested_with_own"
  end

  prepend NestModule
end

describe ::Collapsium::Support::Methods do
  context "#wrap_method" do
    it "fails if there is no method to wrap" do
      expect do
        class NoMethodToWrap
          prepend First
        end
      end.to raise_error(NameError)
    end

    context FirstThenSecond do
      let(:tester) { FirstThenSecond.new }

      it "uses only the second module's return value for non-calling methods" do
        expect(tester.test).to eql 'second'
      end

      it "wraps results appropriately for calling methods" do
        expect(tester.calling_test).to eql 'second: first: first_then_second'
      end
    end

    context SecondThenFirst do
      let(:tester) { SecondThenFirst.new }

      it "uses only the second module's return value for non-calling methods" do
        expect(tester.test).to eql 'first'
      end

      it "wraps results appropriately for calling methods" do
        expect(tester.calling_test).to eql 'first: second: second_then_first'
      end
    end

    context Included do
      let(:tester) { Included.new }

      it "uses only the included module's return value for non-calling methods" do
        expect(tester.test).to eql 'include_module'
      end

      it "wraps results appropriately for calling methods" do
        expect(tester.calling_test).to eql 'include_module: included'
      end
    end

    context PrependNested do
      let(:tester) { PrependNested.new }

      it "uses only the included module's return value for non-calling methods" do
        expect(tester.test).to eql 'include_module'
      end

      it "wraps results appropriately for calling methods" do
        expect(tester.calling_test).to eql 'include_module: nest_module'
      end
    end

    context IncludeNested do
      let(:tester) { IncludeNested.new }

      it "uses only the included module's return value for non-calling methods" do
        expect(tester.test).to eql 'include_module'
      end

      it "wraps results appropriately for calling methods" do
        expect(tester.calling_test).to eql 'include_module: nest_module'
      end
    end

    context IncludeNestedWithOwn do
      let(:tester) { IncludeNestedWithOwn.new }

      it "uses only the own class result for non-calling methods" do
        expect(tester.test).to eql 'include_nested_with_own'
      end

      it "uses only the own class result for calling methods" do
        expect(tester.calling_test).to eql 'include_nested_with_own'
      end
    end

    context PrependNestedWithOwn do
      let(:tester) { PrependNestedWithOwn.new }

      it "ignores class methods for non-calling methods" do
        expect(tester.test).to eql 'include_module'
      end

      it "ignores class methods for calling methods" do
        expect(tester.calling_test).to eql 'include_module: nest_module'
      end
    end
  end
end
