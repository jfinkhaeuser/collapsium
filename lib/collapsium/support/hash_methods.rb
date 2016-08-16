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
      # Read access methods with key parameter
      KEYED_READ_METHODS = [
        :[], :default, :delete, :fetch, :has_key?, :include?, :key?,
      ].freeze

      # @api private
      # All read access methods
      READ_METHODS = KEYED_READ_METHODS + [
        :dup,
      ].freeze

      # @api private
      # Write access methods with key parameter
      KEYED_WRITE_METHODS = [
        :[]=, :store,
      ].freeze

      # All write access methods
      WRITE_METHODS = KEYED_WRITE_METHODS + [
        :merge, :merge!,
      ].freeze

    end # module HashMethods

  end # module Support

end # module Collapsium
