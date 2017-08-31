# coding: utf-8
#
# collapsium
# https://github.com/jfinkhaeuser/collapsium
#
# Copyright (c) 2016-2017 Jens Finkhaeuser and other collapsium contributors.
# All rights reserved.
#

require 'collapsium/viral_capabilities'
require 'collapsium/indifferent_access'

module Collapsium
  ##
  # Provides recursive sort functions for hashes.
  module RecursiveSort
    # Virality means we don't have to rextend with RecursiveSort to sort
    # nested values recursively.
    extend ViralCapabilities

    ##
    # Recursively sort a Hash by its keys. Without a block, this function will
    # not be able to compare keys of different size.
    def recursive_sort!(&block)
      # If we have IndifferentAccess, we need to sort keys appropriately.
      the_keys = nil
      if singleton_class.ancestors.include?(IndifferentAccess)
        the_keys = IndifferentAccess.sorted_keys(keys, &block)
      else
        the_keys = keys.sort(&block)
      end

      return the_keys.reduce(self) do |seed, key|
        # Delete (and later re-insert) value for ordering
        value = self[key]
        delete(key)

        # Recurse into Hash values
        if value.is_a?(Hash)
          value.recursive_sort!(&block)
        end

        # re-insert value
        self[key] = value

        next seed
      end
    end

    ##
    # Same as #recursive_sort!, but returns a copy.
    def recursive_sort(&block)
      ret = nil
      if respond_to?(:recursive_dup)
        ret = recursive_dup
      else
        ret = dup
      end
      return ret.recursive_sort!(&block)
    end
  end # module RecursiveSort
end # module Collapsium
