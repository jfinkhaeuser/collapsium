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
        owner = base_method.owner.object_id
        the_binding = [method_name, owner]
        @@bindings ||= {}
        @@bindings[owner] ||= []
        if @@bindings[owner].include?(the_binding)
          if options[:raise_on_duplicate]
            msg = "Duplicate binding: #{wrapper_block} as :#{method_name} for #{base_method.owner}"
            raise RuntimeError, msg
          end
          return
        end
        @@bindings[owner] << the_binding

        # Hack for calling the private method "define_method"
        def_method.call(method_name) do |*args, &method_block|
          # Prepend the old method to the argument list; but bind it to the current
          # instance.
          wrapped_method = base_method.bind(self)
          args.unshift(wrapped_method)

          # Then yield to the given wrapper block. The wrapper should decide
          # whether to call the old method or not.
          next wrapper_block.call(*args, &method_block)
        end
      end

    end # module Methods

  end # module Support

end # module Collapsium
