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

      merger = proc do |_, v1, v2|
        # rubocop:disable Style/GuardClause
        if v1.is_a? Hash and v2.is_a? Hash
          next v1.merge!(v2, &merger)
        elsif v1.is_a? Array and v2.is_a? Array
          next v1 + v2
        end
        if overwrite
          next v2
        else
          next v1
        end
        # rubocop:enable Style/GuardClause
      end
      merge!(other, &merger)
    end

    ##
    # Same as `dup.recursive_merge!`
    # @param (see #recursive_merge!)
    def recursive_merge(other, overwrite = true)
      return dup.recursive_merge!(other, overwrite)
    end
  end # module RecursiveMerge
end # module Collapsium
