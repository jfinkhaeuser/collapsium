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

      the_merger = proc do |the_self, v1, v2|
        if v1.is_a? Hash and v2.is_a? Hash
          v1 = ViralCapabilities.enhance_value(the_self, v1)
          v2 = ViralCapabilities.enhance_value(the_self, v2)

          keys = (v1.keys + v2.keys).map(&:to_sym).uniq
          keys.each do |key|
            v1_inner = v1[key]
            v2_inner = v2[key]
            if not v1_inner.nil? and not v2_inner.nil?
              v1[key] = the_merger.call(the_self, v1_inner, v2_inner)
            elsif not v1_inner.nil?
              # Nothing to do, we have v1[key]
            else
              # v2.key?(key) is true
              v1[key] = v2_inner
            end
          end
          next v1
        elsif v1.is_a? Array and v2.is_a? Array
          next v1 + v2
        end

        if overwrite
          next v2
        end
        next v1
      end

      # We can't call merge! because that will only be invoked for keys that
      # are missing, and default_proc doesn't seem to be used there. So we need
      # to call a custom merge function.
      new_self = the_merger.call(self, self, other)
      replace(new_self)
    end

    ##
    # Same as `dup.recursive_merge!`
    # @param (see #recursive_merge!)
    def recursive_merge(other, overwrite = true)
      return dup.recursive_merge!(other, overwrite)
    end
  end # module RecursiveMerge
end # module Collapsium
