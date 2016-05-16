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
  # Provides recursive sort functions for hashes.
  module RecursiveSort
    ##
    # Recursively sort a Hash by its keys. Without a block, this function will
    # not be able to compare keys of different size.
    def recursive_sort!(&block)
      return keys.sort(&block).reduce(self) do |seed, key|
        # Delete (and later re-insert) value for ordering
        value = self[key]
        delete(key)

        # Recurse into Hash values
        if value.is_a?(Hash)
          value.extend(RecursiveSort)
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
      ret.extend(RecursiveSort)
      return ret.recursive_sort!(&block)
    end

    #    def recursive_merge!(other, overwrite = true)
    #      if other.nil?
    #        return self
    #      end
    #
    #      merger = proc do |_, v1, v2|
    #        # rubocop:disable Style/GuardClause
    #        if v1.is_a? Hash and v2.is_a? Hash
    #          next v1.merge(v2, &merger)
    #        elsif v1.is_a? Array and v2.is_a? Array
    #          next v1 + v2
    #        end
    #        if overwrite
    #          next v2
    #        else
    #          next v1
    #        end
    #        # rubocop:enable Style/GuardClause
    #      end
    #      merge!(other, &merger)
    #    end
    #
    #    ##
    #    # Same as `dup.recursive_merge!`
    #    # @param (see #recursive_merge!)
    #    def recursive_merge(other, overwrite = true)
    #      copy = dup
    #      copy.extend(RecursiveMerge)
    #      return copy.recursive_merge!(other, overwrite)
    #    end
  end # module RecursiveSort
end # module Collapsium
