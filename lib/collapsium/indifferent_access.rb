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
  # Provides indifferent access to string/symbol keys in a Hash. That is,
  # if your hash contains a string key, you can also access it via a symbol
  # and vice versa.
  module IndifferentAccess

    ##
    # Set your Hash's #default_proc to DEFAULT_PROC, and you've got indifferent
    # access.
    DEFAULT_PROC = proc do |hash, key|
      case key
      when String
        sym = key.to_sym
        hash[sym] if hash.key?(sym)
      when Symbol
        str = key.to_s
        hash[str] if hash.key?(str)
      end
    end.freeze

  end # module IndifferentAccess

end # module Collapsium
