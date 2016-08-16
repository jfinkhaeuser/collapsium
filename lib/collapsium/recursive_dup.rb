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
  # Provides recursive (deep) dup function for hashes.
  module RecursiveDup
    # Clone Hash extensions for nested Hashes
    extend ViralCapabilities

    def recursive_dup
      ret = map do |k, v|
        # Hash values, recurse into them.
        if v.is_a?(Hash)
          n = ViralCapabilities.enhance_hash_value(self, v)
          next [k, n.recursive_dup]
        end

        begin
          # Other duplicatable values
          next [k, v.dup]
        rescue TypeError
          # Values such as e.g. Fixnum
          next [k, v]
        end
      end
      ret = Hash[ret]
      return ViralCapabilities.enhance_hash_value(self, ret)
    end

    alias deep_dup recursive_dup
  end # module RecursiveDup
end # module Collapsium
