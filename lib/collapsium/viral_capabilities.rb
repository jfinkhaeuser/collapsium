# coding: utf-8
#
# collapsium
# https://github.com/jfinkhaeuser/collapsium
#
# Copyright (c) 2016 Jens Finkhaeuser and other collapsium contributors.
# All rights reserved.
#

require 'collapsium/support/hash_methods'
require 'collapsium/support/methods'


module Collapsium
  ##
  # Tries to make extended Hash capabilities viral, i.e. provides the same
  # features to nested Hash structures as the Hash that includes this module.
  #
  # Virality is ensured by changing the return value of various methods; if it
  # is derived from Hash, it is attempted to convert it to the including class.
  #
  # The module uses HashMethods to decide which methods to make viral in this
  # manner.
  #
  # There are two ways for using this module:
  # a) in a `Class`, either include, prepend or extend it.
  # b) in a `Module`, *extend* this module. The resulting module can be included,
  #    prepended or extended in a `Class` again.
  module ViralCapabilities

    include ::Collapsium::Support::HashMethods
    include ::Collapsium::Support::Methods

    ##
    # When prepended, included or extended, enhance the base.
    def prepended(base)
      ViralCapabilities.enhance(base)
    end

    def included(base)
      ViralCapabilities.enhance(base)
    end

    def extended(base)
      ViralCapabilities.enhance(base)
    end

    class << self
      include ::Collapsium::Support::HashMethods
      include ::Collapsium::Support::Methods

      ##
      # When prepended, included or extended, enhance the base.
      def prepended(base)
        enhance(base)
      end

      def included(base)
        enhance(base)
      end

      def extended(base)
        enhance(base)
      end

      ##
      # Enhance the base by wrapping all READ_METHODS and WRITE_METHODS in
      # a wrapper that uses enhance_hash_value to, well, enhance Hash results.
      def enhance(base)
        @@write_block ||= proc { |super_method, *args, &block|
          arg_copy = args.map { |arg| enhance_hash_value(super_method.receiver, arg) }
          result = super_method.call(*arg_copy, &block)
          next enhance_hash_value(super_method.receiver, result)
        }
        @@read_block ||= proc { |super_method, *args, &block|
          result = super_method.call(*args, &block)
          next enhance_hash_value(super_method.receiver, result)
        }

        READ_METHODS.each do |method_name|
          wrap_method(base, method_name, &@@read_block)
        end

        WRITE_METHODS.each do |method_name|
          wrap_method(base, method_name, &@@write_block)
        end
      end

      ##
      # Given an outer Hash and a value, enhance Hash values so that they have
      # the same capabilities as the outer Hash. Non-Hash values are returned
      # unchanged.
      def enhance_hash_value(outer_hash, value)
        # If the value is not a Hash, we don't do anything.
        if not value.is_a? Hash
          return value
        end

        # If the value is a different type of Hash from ourself, we want to
        # create an instance of our own type with the same values.
        # XXX: DO NOT replace the loop with :merge! or :merge - those are
        #      potentially wrapped write functions, leading to an infinite
        #      recursion.
        if value.class != outer_hash.class
          new_value = outer_hash.class.new

          value.each do |key, inner_val|
            if not inner_val.is_a? Hash
              new_value[key] = inner_val
              next
            end

            if inner_val.class != outer_hash.class
              new_inner_value = outer_hash.class.new
              new_inner_value.merge!(inner_val)
              new_value[key] = new_inner_value
            end
          end
          value = new_value
        end

        # Next, we want to extend all the modules in self. That might be a
        # no-op due to the above block, but not necessarily so.
        value_mods = (class << value; self end).included_modules
        own_mods = (class << outer_hash; self end).included_modules
        (own_mods - value_mods).each do |mod|
          value.extend(mod)
        end

        # If we have a default_proc and the value doesn't, we want to use our
        # own. This *can* override a perfectly fine default_proc with our own,
        # which might suck.
        value.default_proc ||= outer_hash.default_proc


        # Finally, the class can define its own virality function.
        if outer_hash.respond_to?(:virality)
          value = outer_hash.virality(value)
        end

        return value
      end
    end

  end # module ViralCapabilities
end # module Collapsium
