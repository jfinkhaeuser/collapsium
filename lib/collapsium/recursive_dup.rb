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
  # Provides recursive (deep) dup function for hashes.
  module RecursiveDup
    def recursive_dup
      ret = map do |k, v|
        # Hash values, recurse into them.
        if v.is_a?(Hash)
          n = v.dup # we duplicate v to not extend it.
          n.extend(RecursiveDup)
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
      return Hash[ret]
    end

    alias deep_dup recursive_dup
  end # module RecursiveDup
end # module Collapsium
