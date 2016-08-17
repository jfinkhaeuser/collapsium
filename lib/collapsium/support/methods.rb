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
      #         wrap_method(base, :method_to_wrap) do |wrapped_method, *args, &block|
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
        options[:raise_on_duplicate] ||= false
        options[:prevent_duplicates] ||= false

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
            if options[:raise_on_missing]
              raise
            end
            return
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

        # Prevent duplicate bindings.
        if options[:prevent_duplicates]
          owner = base_method.owner.object_id
          the_binding = [method_name, owner]
          @@__collapsium_methods_bindings ||= {}
          @@__collapsium_methods_bindings[owner] ||= []
          if @@__collapsium_methods_bindings[owner].include?(the_binding)
            if options[:raise_on_duplicate]
              msg = "Duplicate binding: #{wrapper_block} as :#{method_name} for #{base_method.owner}"
              raise RuntimeError, msg
            end
            return
          end
          @@__collapsium_methods_bindings[owner] << the_binding
        end

        # Hack for calling the private method "define_method"
        def_method.call(method_name) do |*args, &method_block|
          # We're trying to prevent loops by maintaining a stack of wrapped
          # method invocations.
          @__collapsium_methods_callstack ||= []

          # Our current binding is based on the wrapper block and our own class.
          the_binding = [wrapper_block.object_id, self.class.object_id]

          # We'll either pass the wrapped method to the wrapper block, or invoke
          # it ourselves.
          wrapped_method = base_method.bind(self)

          # We're trying to find a loop in the callstack with this current
          # binding already appended.
          stack = @__collapsium_methods_callstack.dup
          stack << the_binding
          loops = Methods.repeated(stack)

          # If we do find a loop with the current binding involved, we'll just
          # call the wrapped method.
          if loops.include?(the_binding)
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

      def self.repeated(array)
        counts = Hash.new(0)
        array.each{|val|counts[val]+=1}
        counts.reject{|val,count|count==1}.keys
      end

    end # module Methods

  end # module Support

end # module Collapsium
