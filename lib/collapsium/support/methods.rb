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
      # The block must accept the super_method as the first parameter, followed
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
      #         wrap_method(base, :method_to_wrap) do |super_method, *args, &block|
      #           # modify args, if desired
      #           result = super_method.call(*args, &block)
      #           # do something with the result, if desired
      #           next result
      #         end
      #       end
      #     end
      #   end
      # ```
      def wrap_method(base, method_name, &wrapper_block)
        # The base class must define an instance method of method_name, otherwise
        # this will NameError. That's also a good check that sensible things are
        # being done.
        base_method = base.instance_method(method_name.to_sym)

        # Hack for calling the private method "define_method"
        def_method = base.method(:define_method)
        def_method.call(method_name) do |*args, &method_block|
          # Prepend the old method to the argument list; but bind it to the current
          # instance.
          super_method = base_method.bind(self)
          args.unshift(super_method)

          # Then yield to the given wrapper block. The wrapper should decide
          # whether to call the old method or not.
          next wrapper_block.call(*args, &method_block)
        end
      end

    end # module Methods

  end # module Support

end # module Collapsium
