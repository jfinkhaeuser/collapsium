# coding: utf-8
#
# collapsium
# https://github.com/jfinkhaeuser/collapsium
#
# Copyright (c) 2016 Jens Finkhaeuser and other collapsium contributors.
# All rights reserved.
#

require 'collapsium/viral_capabilities'

module Collapsium
  ##
  # Provides recursive merge functions for hashes.
  module RecursiveMerge

    # Make the capabilities of classes using RecursiveMerge viral.
    extend ViralCapabilities

    ##
    # Recursively merge `:other` into this Hash.
    #
    # This starts by merging the leaf-most Hash entries. Arrays are merged
    # by addition.
    #
    # For everything that's neither Hash or Array, if the `:overwrite`
    # parameter is true, the entry from `:other` is used. Otherwise the entry
    # from `:self` is used.
    #
    # @param other [Hash] the hash to merge into `:self`
    # @param overwrite [Boolean] see method description.
    def recursive_merge!(other, overwrite = true)
      if other.nil?
        return self
      end

      # We can't call merge! because that will only be invoked for keys that
      # are missing, and default_proc doesn't seem to be used there. So we need
      # to call a custom merge function.
      new_self = RecursiveMerge.merger(self, self, other, overwrite)
      replace(new_self)
    end

    ##
    # Same as `dup.recursive_merge!`
    # @param (see #recursive_merge!)
    def recursive_merge(other, overwrite = true)
      return dup.recursive_merge!(other, overwrite)
    end

    class << self
      def merged_keys(the_self, v1, v2)
        keys = (v1.keys + v2.keys).uniq
        if the_self.singleton_class.ancestors.include?(IndifferentAccess)
          # We want to preserve each Hash's key types as much as possible, but
          # IndifferentAccess doesn't care about types. We can use it to figure out
          # which unique keys only exist in v2.
          only_v2 = IndifferentAccess.unique_keys(keys) \
                    - IndifferentAccess.unique_keys(v1.keys)

          # At this point, IndifferentAccess may have modified the key types
          # in only_v2. To get back the original types, we can iterate the
          # Hash and remember all keys that are indifferently contained in
          # only_v2.
          original_types = []
          v2.each do |key, _|
            unique = IndifferentAccess.unique_keys([key])
            if only_v2.include?(unique[0])
              original_types << key
            end
          end
          keys = v1.keys + original_types
        end
        return keys
      end

      def merger(the_self, v1, v2, overwrite)
        if v1.is_a? Hash and v2.is_a? Hash
          v1 = ViralCapabilities.enhance_value(the_self, v1)
          v2 = ViralCapabilities.enhance_value(the_self, v2)

          # IndifferentAccess has its own idea of which keys are unique, so if
          # we use it, we must consult it.
          keys = merged_keys(the_self, v1, v2)
          new_val = ViralCapabilities.enhance_value(the_self, {})
          keys.each do |key|
            v1_inner = v1[key]
            v2_inner = v2[key]
            if not v1_inner.nil? and not v2_inner.nil?
              new_val[key] = RecursiveMerge.merger(the_self, v1_inner, v2_inner,
                                                   overwrite)
            elsif not v1_inner.nil?
              # Nothing to do, we have v1[key]
              new_val[key] = v1_inner
            else
              # v2.key?(key) is true
              new_val[key] = v2_inner
            end
          end

          v1.replace(new_val)
          return v1
        elsif v1.is_a? Array and v2.is_a? Array
          return v1 + v2
        end

        if overwrite
          return v2
        end
        return v1
      end
    end # class << self
  end # module RecursiveMerge
end # module Collapsium
