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
  # Provides recursive (deep) fetch function for hashes.
  module RecursiveFetch
    # Clone Hash extensions for nested Hashes
    extend ViralCapabilities

    ##
    # Fetches the first matching key, or the default value if no match
    # was found.
    # If a block is given, it is passed the value containing the key
    # (the parent), the value at the key, and the default value
    # in that order.
    # *Note:* Be careful when using blocks: it's return value becomes
    # the match value. The typically correct behaviour is to return
    # the match value passed to the block.
    def recursive_fetch_one(key, default = nil, &block)
      # Start simple at the top level.
      # rubocop:disable Lint/HandleExceptions
      begin
        result = fetch(key, default)
        if result != default
          if not block.nil?
            result = yield self, result, default
          end
          return result
        end
      rescue TypeError
        # Happens if self is an Array and key is a String that cannot
        # be converted to Integer.
      end
      # rubocop:enable Lint/HandleExceptions

      # We have to recurse for nested values
      result = map do |_, v|
        # If we have a Hash or Array, we need to recurse.
        if not (v.is_a? Hash or v.is_a? Array)
          next
        end

        enhanced = ViralCapabilities.enhance_value(self, v)
        inner = enhanced.recursive_fetch_one(key, default, &block)
        if inner != default
          next inner
        end
      end

      result.compact!
      return result[0] || default
    end

    ##
    # Fetches all matching keys as an array, or the default value if no match
    # was found. Blocks work as in `#recursive_fetch`
    def recursive_fetch_all(key, default = nil, &block)
      result = []

      # Start simple at the top level.
      # rubocop:disable Lint/HandleExceptions
      begin
        ret = fetch(key, default)
        if ret != default
          if not block.nil?
            ret = yield self, ret, default
          end
          result << ret
        end
      rescue TypeError
        # Happens if self is an Array and key is a String that cannot
        # be converted to Integer.
      end
      # rubocop:enable Lint/HandleExceptions

      # We have to recurse for nested values
      result += map do |_, v|
        # If we have a Hash or Array, we need to recurse.
        if not (v.is_a? Hash or v.is_a? Array)
          next
        end

        enhanced = ViralCapabilities.enhance_value(self, v)
        inner = enhanced.recursive_fetch_all(key, default, &block)
        if inner != default
          next inner
        end
      end

      # Flatten and compact results to weed out non-matches
      result = result.flatten
      result.compact!

      if result.empty?
        return default
      end
      return result
    end

    alias recursive_fetch recursive_fetch_all
  end # module RecursiveFetch
end # module Collapsium
