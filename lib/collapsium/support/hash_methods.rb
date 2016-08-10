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
  # Support functionality for Collapsium
  module Support

    ##
    # @api private
    # Defines which read and write functions we expect Hash to have.
    module HashMethods

      # @api private
      # Methods redefined to support pathed read access.
      READ_METHODS = [
        :[], :default, :delete, :dup, :fetch, :has_key?, :include?, :key?, :member?,
      ].freeze

      # @api private
      # Methods redefined to support pathed write access.
      WRITE_METHODS = [
        :[]=, :store, :merge, :merge!,
      ].freeze

    end # module HashMethods

  end # module Support

end # module Collapsium
