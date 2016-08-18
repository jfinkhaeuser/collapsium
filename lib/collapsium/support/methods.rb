# coding: utf-8
#
# collapsium
# https://github.com/jfinkhaeuser/collapsium
#
# Copyright (c) 2016 Jens Finkhaeuser and other collapsium contributors.
# All rights reserved.
#

module Collapsium

  ##
  # Support functionality for Collapsium
  module Support

    ##
    # Functionality for extending the behaviour of Hash methods
    module Methods
      ##
      # Given the base module, wraps the given method name in the given block.
      # The block must accept the wrapped_method as the first parameter, followed
      # by any arguments and blocks the super method might accept.
      #
      # The canonical usage example is of a module that when prepended wraps
      # some methods with extra functionality:
      #
      # ```ruby
      #   module MyModule
      #     class << self
      #       include ::Collapsium::Support::Methods
      #
      #       def prepended(base)
      #         wrap_method(base, :method_name) do |wrapped_method, *args, &block|
      #           # modify args, if desired
      #           result = wrapped_method.call(*args, &block)
      #           # do something with the result, if desired
      #           next result
      #         end
      #       end
      #     end
      #   end
      # ```
      def wrap_method(base, method_name, options = {}, &wrapper_block)
        # Option defaults (need to check for nil if we default to true)
        if options[:raise_on_missing].nil?
          options[:raise_on_missing] = true
        end

        # Grab helper methods
        base_method, def_method = resolve_helpers(base, method_name,
                                                  options[:raise_on_missing])
        if base_method.nil?
          # Indicates that we're not done building a Module yet
          return
        end

        # Hack for calling the private method "define_method"
        def_method.call(method_name) do |*args, &method_block|
          # We're trying to prevent loops by maintaining a stack of wrapped
          # method invocations.
          @__collapsium_methods_callstack ||= []

          # Our current binding is based on the wrapper block and our own class,
          # as well as the arguments (CRC32).
          require 'zlib'
          signature = Zlib::crc32(JSON::dump(args))
          the_binding = [wrapper_block.object_id, self.class.object_id, signature]

          # We'll either pass the wrapped method to the wrapper block, or invoke
          # it ourselves.
          wrapped_method = base_method.bind(self)

          # If we do find a loop with the current binding involved, we'll just
          # call the wrapped method.
          if Methods.loop_detected?(the_binding, @__collapsium_methods_callstack)
            next wrapped_method.call(*args, &method_block)
          end

          # If there is no loop, call the wrapper block and pass along the
          # wrapped method as the first argument.
          args.unshift(wrapped_method)

          # Then yield to the given wrapper block. The wrapper should decide
          # whether to call the old method or not. But by modifying our stack
          # before/after the invocation, we allow the loop detection above to
          # work.
          @__collapsium_methods_callstack << the_binding
          result = wrapper_block.call(*args, &method_block)
          @__collapsium_methods_callstack.pop

          next result
        end
      end

      def resolve_helpers(base, method_name, raise_on_missing)
        # The base class must define an instance method of method_name, otherwise
        # this will NameError. That's also a good check that sensible things are
        # being done.
        base_method = nil
        def_method = nil
        if base.is_a? Module
          # Modules *may* not be fully defined when this is called, so in some
          # cases it's best to ignore NameErrors.
          begin
            base_method = base.instance_method(method_name.to_sym)
          rescue NameError
            if raise_on_missing
              raise
            end
            return base_method, def_method
          end
          def_method = base.method(:define_method)
        else
          # For Objects and Classes, the unbound method will later be bound to
          # the object or class to define the method on.
          base_method = base.method(method_name.to_s).unbind
          # With regards to method defintion, we only want to define methods
          # for the specific instance (i.e. use :define_singleton_method).
          def_method = base.method(:define_singleton_method)
        end

        return base_method, def_method
      end

      class << self
        # Given an input array, return repeated sequences from the array. It's
        # used in loop detection.
        def repeated(array)
          counts = Hash.new(0)
          array.each { |val| counts[val] += 1 }
          return counts.reject { |_, count| count == 1 }.keys
        end

        # Given a call stack and a binding, returns true if there seems to be a
        # loop in the call stack with the binding causing it, false otherwise.
        def loop_detected?(the_binding, stack)
          # Make a temporary stack with the binding pushed
          tmp_stack = stack.dup
          tmp_stack << the_binding
          loops = Methods.repeated(tmp_stack)

          # If we do find a loop with the current binding involved, we'll just
          # call the wrapped method.
          return loops.include?(the_binding)
        end
      end # class << self

    end # module Methods

  end # module Support

end # module Collapsium
