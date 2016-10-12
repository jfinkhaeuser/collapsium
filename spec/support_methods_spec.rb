require 'spec_helper'
require_relative '../lib/collapsium/support/methods'

module First
  class << self
    include ::Collapsium::Support::Methods

    def extended(base)
      prepended(base)
    end

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

module NonRaising
  class << self
    include ::Collapsium::Support::Methods

    def prepended(base)
      wrap_method(base, :calling_test, raise_on_missing: false) do |super_method, *args, &block|
        result = super_method.call(*args, &block)
        next "nonraising: #{result}"
      end

      wrap_method(base, :test, raise_on_missing: false) do
        next "nonraising"
      end
    end
  end # class << self
end # module NonRaising

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
    it "can wrap objects" do
      class TestClass
        def calling_test
          return "object wrapping"
        end
      end

      tester = nil
      expect { tester = TestClass.new }.not_to raise_error
      expect { tester.extend(First) }.not_to raise_error

      expect(tester.calling_test).to eql "first: object wrapping"
    end

    context FirstThenSecond do
      let(:tester) { FirstThenSecond.new }

      it "uses only the second module's return value for non-calling methods" do
        expect(tester.test).to eql 'second'
      end

      it "wraps results appropriately for calling methods" do
        expect(tester.calling_test).to eql 'second: first: first_then_second'
      end

      it "defines two wrappers for #test" do
        expect(::Collapsium::Support::Methods.wrappers(tester, :test).size).to eql 2
      end

      it "defines two wrappers for #calling_test" do
        expect(::Collapsium::Support::Methods.wrappers(tester, :calling_test).size).to eql 2
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

      it "defines two wrappers for #test" do
        expect(::Collapsium::Support::Methods.wrappers(tester, :test).size).to eql 2
      end

      it "defines two wrappers for #calling_test" do
        expect(::Collapsium::Support::Methods.wrappers(tester, :calling_test).size).to eql 2
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

      it "defines two wrappers for #test" do
        expect(::Collapsium::Support::Methods.wrappers(tester, :test).size).to eql 1
      end

      it "defines two wrappers for #calling_test" do
        expect(::Collapsium::Support::Methods.wrappers(tester, :calling_test).size).to eql 1
      end    end

    context PrependNested do
      let(:tester) { PrependNested.new }

      it "uses only the included module's return value for non-calling methods" do
        expect(tester.test).to eql 'include_module'
      end

      it "wraps results appropriately for calling methods" do
        expect(tester.calling_test).to eql 'include_module: nest_module'
      end

      it "defines two wrappers for #test" do
        expect(::Collapsium::Support::Methods.wrappers(tester, :test).size).to eql 1
      end

      it "defines two wrappers for #calling_test" do
        expect(::Collapsium::Support::Methods.wrappers(tester, :calling_test).size).to eql 1
      end    end

    context IncludeNested do
      let(:tester) { IncludeNested.new }

      it "uses only the included module's return value for non-calling methods" do
        expect(tester.test).to eql 'include_module'
      end

      it "wraps results appropriately for calling methods" do
        expect(tester.calling_test).to eql 'include_module: nest_module'
      end

      it "defines two wrappers for #test" do
        expect(::Collapsium::Support::Methods.wrappers(tester, :test).size).to eql 1
      end

      it "defines two wrappers for #calling_test" do
        expect(::Collapsium::Support::Methods.wrappers(tester, :calling_test).size).to eql 1
      end    end

    context IncludeNestedWithOwn do
      let(:tester) { IncludeNestedWithOwn.new }

      it "uses only the own class result for non-calling methods" do
        expect(tester.test).to eql 'include_nested_with_own'
      end

      it "uses only the own class result for calling methods" do
        expect(tester.calling_test).to eql 'include_nested_with_own'
      end

      it "defines two wrappers for #test" do
        expect(::Collapsium::Support::Methods.wrappers(tester, :test).size).to eql 1
      end

      it "defines two wrappers for #calling_test" do
        expect(::Collapsium::Support::Methods.wrappers(tester, :calling_test).size).to eql 1
      end    end

    context PrependNestedWithOwn do
      let(:tester) { PrependNestedWithOwn.new }

      it "ignores class methods for non-calling methods" do
        expect(tester.test).to eql 'include_module'
      end

      it "ignores class methods for calling methods" do
        expect(tester.calling_test).to eql 'include_module: nest_module'
      end

      it "defines two wrappers for #test" do
        expect(::Collapsium::Support::Methods.wrappers(tester, :test).size).to eql 1
      end

      it "defines two wrappers for #calling_test" do
        expect(::Collapsium::Support::Methods.wrappers(tester, :calling_test).size).to eql 1
      end
    end

    context "failing" do
      context "classes" do
        it "fails if there is no method to wrap" do
          expect do
            class NoMethodToWrap1
              prepend First
            end
          end.to raise_error(NameError)
        end

        it "fails silently if asked not to raise" do
          expect do
            class NoMethodToWrap2
              prepend NonRaising
            end
          end.not_to raise_error
        end
      end

      context "objects" do
        class EmptyClass
        end

        it "fails if there is no method to wrap" do
          expect do
            tester = EmptyClass.new
            tester.extend(First)
          end.to raise_error(NameError)
        end

        it "fails silently if asked not to raise" do
          expect do
            tester = EmptyClass.new
            tester.extend(NonRaising)
          end.not_to raise_error
        end
      end
    end
  end

  context "#wrappers" do
    it "finds wrappers in FirstThenSecond" do
      expect(::Collapsium::Support::Methods.wrappers(FirstThenSecond, :test).size).to eql 2
    end

    it "finds wrappers in SecondThenFirst" do
      expect(::Collapsium::Support::Methods.wrappers(SecondThenFirst, :test).size).to eql 2
    end

    it "finds wrappers in Included" do
      expect(::Collapsium::Support::Methods.wrappers(Included, :test).size).to eql 1
    end

    it "finds wrappers in NestModule" do
      expect(::Collapsium::Support::Methods.wrappers(NestModule, :test).size).to eql 1
    end

    it "finds wrappers in PrependNested" do
      expect(::Collapsium::Support::Methods.wrappers(PrependNested, :test).size).to eql 1
    end

    it "finds wrappers in IncludeNested" do
      expect(::Collapsium::Support::Methods.wrappers(IncludeNested, :test).size).to eql 1
    end

    it "finds wrappers in PrependNestedWithOwn" do
      expect(::Collapsium::Support::Methods.wrappers(PrependNestedWithOwn, :test).size).to eql 1
    end

    it "finds wrappers in IncludeNestedWithOwn" do
      expect(::Collapsium::Support::Methods.wrappers(IncludeNestedWithOwn, :test).size).to eql 1
    end

    it "does not find wrappers on undecorated Hashes" do
      expect(::Collapsium::Support::Methods.wrappers({}, :test)).to be_empty
    end
  end

  context "loop detection" do
  end
end
