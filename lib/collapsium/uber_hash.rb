# coding: utf-8
#
# collapsium
# https://github.com/jfinkhaeuser/collapsium
#
# Copyright (c) 2016 Jens Finkhaeuser and other collapsium contributors.
# All rights reserved.
#

require 'collapsium/recursive_merge'
require 'collapsium/recursive_dup'
require 'collapsium/recursive_sort'
require 'collapsium/indifferent_access'
require 'collapsium/pathed_access'
require 'collapsium/prototype_match'

module Collapsium

  # A Hash that includes all the different Hash extensions in collapsium
  class UberHash < Hash
    include RecursiveMerge
    include RecursiveDup
    include RecursiveSort
    include PathedAccess
    include PrototypeMatch

    def initialize(*args)
      super

      # Activate IndifferentAccess
      self.default_proc = IndifferentAccess::DEFAULT_PROC

      # Extra functionality: allow being initialized by a Hash
      if args.empty? or not args[0].is_a?(Hash)
        return
      end

      recursive_merge!(args[0])
    end

    def dup
      return UberHash.new(self)
    end
  end

end # module Collapsium
