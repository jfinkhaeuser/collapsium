# coding: utf-8
#
# collapsium
# https://github.com/jfinkhaeuser/collapsium
#
# Copyright (c) 2016 Jens Finkhaeuser and other collapsium contributors.
# All rights reserved.
#

require 'collapsium/support/hash_methods'
require 'collapsium/support/array_methods'
require 'collapsium/support/methods'

module Collapsium
  ##
  # Tries to make extended Hash capabilities viral, i.e. provides the same
  # features to nested Hash structures as the Hash that includes this module.
  #
  # Virality is ensured by changing the return value of various methods; if it
  # is derived from Hash, it is attempted to convert it to the including class.
  #
  # The module uses HashMethods and ArrayMethods to decide which methods to make
  # viral in this manner.
  #
  # There are two ways for using this module:
  # a) in a `Class`, either include, prepend or extend it.
  # b) in a `Module`, *extend* this module. The resulting module can be included,
  #    prepended or extended in a `Class` again.
  module ViralCapabilities
    # The default ancestor values for the accessors in ViralAncestorTypes
    # are defined here. They're also used for generating functions that should
    # provide the best ancestor class.
    DEFAULT_ANCESTORS = {
      hash_ancestor: Hash,
      array_ancestor: Array,
    }.freeze

    ##
    # Any Object (Class, Module) that's enhanced with ViralCapabilities will at
    # least be extended with a module defining its Hash and Array ancestors.
    module ViralAncestorTypes
      def hash_ancestor
        return @hash_ancestor || DEFAULT_ANCESTORS[:hash_ancestor]
      end
      attr_writer :hash_ancestor

      def array_ancestor
        return @array_ancestor || DEFAULT_ANCESTORS[:array_ancestor]
      end
      attr_writer :array_ancestor
    end

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

      # We want to wrap methods for Arrays and Hashes alike
      READ_METHODS = (
        ::Collapsium::Support::HashMethods::READ_METHODS \
        + ::Collapsium::Support::ArrayMethods::READ_METHODS
      ).uniq.freeze
      WRITE_METHODS = (
        ::Collapsium::Support::HashMethods::WRITE_METHODS \
        + ::Collapsium::Support::ArrayMethods::WRITE_METHODS
      ).uniq.freeze

      ##
      # Enhance the base by wrapping all READ_METHODS and WRITE_METHODS in
      # a wrapper that uses enhance_value to, well, enhance Hash and Array
      # results.
      def enhance(base)
        # rubocop:disable Style/ClassVars
        @@write_block ||= proc do |wrapped_method, *args, &block|
          arg_copy = args.map do |arg|
            enhance_value(wrapped_method.receiver, arg)
          end
          result = wrapped_method.call(*arg_copy, &block)
          next enhance_value(wrapped_method.receiver, result)
        end
        @@read_block ||= proc do |wrapped_method, *args, &block|
          result = wrapped_method.call(*args, &block)
          next enhance_value(wrapped_method.receiver, result)
        end
        # rubocop:enable Style/ClassVars

        # Minimally: add the ancestor functions to classes
        if base.is_a? Class
          base.include(ViralAncestorTypes)
        end

        READ_METHODS.each do |method_name|
          wrap_method(base, method_name, raise_on_missing: false, &@@read_block)
        end

        WRITE_METHODS.each do |method_name|
          wrap_method(base, method_name, raise_on_missing: false, &@@write_block)
        end
      end

      ##
      # Enhance Hash or Array value
      def enhance_value(parent, value, *args)
        if value.is_a? Hash
          value = enhance_hash_value(parent, value, *args)
        elsif value.is_a? Array
          value = enhance_array_value(parent, value, *args)
        end

        # It's possible that the value is a Hash or an Array, but there's no
        # ancestor from which capabilities can be copied. We can find out by
        # checking whether any wrappers are defined for it.
        needs_wrapping = true
        READ_METHODS.each do |method_name|
          wrappers = ::Collapsium::Support::Methods.wrappers(value, method_name)
          # rubocop:disable Style/Next
          if wrappers.include?(@@read_block)
            # all done
            needs_wrapping = false
            break
          end
          # rubocop:enable Style/Next
        end

        # If we have a Hash or Array value that needs enhancing still, let's
        # do that.
        if needs_wrapping and (value.is_a? Array or value.is_a? Hash)
          enhance(value)
        end

        return value
      end

      def enhance_array_value(parent, value, *args)
        # If the value is not of the best ancestor type, make sure it becomes
        # that type.
        # XXX: DO NOT replace the loop with a simpler function - it could lead
        #      to infinite recursion!
        enc_class = array_ancestor(parent, value)
        if value.class != enc_class
          new_value = enc_class.new
          value.each do |item|
            if not item.is_a? Hash and not item.is_a? Array
              new_value << item
              next
            end

            new_item = enhance_value(value, item)
            new_value << new_item
          end
          value = new_value
        end

        # Copy all modules from the parent to the value
        copy_mods(parent, value)

        # Set appropriate ancestors on the value
        set_ancestors(parent, value)

        return call_virality(parent, value, *args)
      end

      ##
      # Given an outer Hash and a value, enhance Hash values so that they have
      # the same capabilities as the outer Hash. Non-Hash values are returned
      # unchanged.
      def enhance_hash_value(parent, value, *args)
        # If the value is not of the best ancestor type, make sure it becomes
        # that type.
        # XXX: DO NOT replace the loop with :merge! or :merge - those are
        #      potentially wrapped write functions, leading to an infinite
        #      recursion.
        enc_class = hash_ancestor(parent, value)

        if value.class != enc_class
          new_value = enc_class.new

          value.each do |key, item|
            if not item.is_a? Hash and not item.is_a? Array
              new_value[key] = item
              next
            end

            new_item = enhance_value(value, item)
            new_value[key] = new_item
          end
          value = new_value
        end

        # Copy all modules from the parent to the value
        copy_mods(parent, value)

        # If we have a default_proc and the value doesn't, we want to use our
        # own. This *can* override a perfectly fine default_proc with our own,
        # which might suck.
        if parent.respond_to?(:default_proc)
          # FIXME: need to inherit this for arrays, too?
          value.default_proc ||= parent.default_proc
        end

        # Set appropriate ancestors on the value
        set_ancestors(parent, value)

        return call_virality(parent, value, *args)
      end

      def copy_mods(parent, value)
        # We want to extend all the modules in self. That might be a
        # no-op due to the above block, but not necessarily so.
        value_mods = (class << value; self end).included_modules
        parent_mods = (class << parent; self end).included_modules
        parent_mods << ViralAncestorTypes
        mods_to_copy = (parent_mods - value_mods).uniq

        # Small fixup for JSON; this doesn't technically belong here, but let's
        # play nice.
        if value.is_a? Array
          mods_to_copy.delete(::JSON::Ext::Generator::GeneratorMethods::Hash)
        elsif value.is_a? Hash
          mods_to_copy.delete(::JSON::Ext::Generator::GeneratorMethods::Array)
        end

        # Copy mods.
        mods_to_copy.each do |mod|
          value.extend(mod)
        end
      end

      def call_virality(parent, value, *args)
        # The parent class can define its own virality function.
        if parent.respond_to?(:virality)
          value = parent.virality(value, *args)
        end

        return value
      end

      DEFAULT_ANCESTORS.each do |getter, default|
        define_method(getter) do |parent, value|
          # We value (haha) the value's stored ancestor over the parent's...
          [value, parent].each do |receiver|
            # rubocop:disable Lint/HandleExceptions
            begin
              klass = receiver.send(getter)
              if klass != default
                return klass
              end
            rescue NoMethodError
            end
            # rubocop:enable Lint/HandleExceptions
          end

          # ... but if neither yield satisfying results, we value the parent's
          # class over the value's. This way parents can propagate their class.
          [parent, value].each do |receiver|
            if receiver.is_a? default
              return receiver.class
            end
          end

          # The default shouldn't really be reached, because it only applies
          # if neither parent nor value are derived from default, and then
          # this functions shouldn't even be called.
          # :nocov:
          return default
          # :nocov:
        end
      end

      def set_ancestors(parent, value)
        DEFAULT_ANCESTORS.each do |getter, default|
          setter = "#{getter}=".to_sym

          ancestor = nil
          if parent.is_a? default
            ancestor = parent.class
          elsif parent.respond_to?(getter)
            ancestor = parent.send(getter)
          else
            ancestor = default
          end

          value.send(setter, ancestor)
        end
      end
    end # class << self

  end # module ViralCapabilities
end # module Collapsium
