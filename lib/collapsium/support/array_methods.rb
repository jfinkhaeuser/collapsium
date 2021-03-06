# coding: utf-8
#
# collapsium
# https://github.com/jfinkhaeuser/collapsium
#
# Copyright (c) 2016-2017 Jens Finkhaeuser and other collapsium contributors.
# All rights reserved.
#

module Collapsium

  ##
  # Support functionality for Collapsium
  module Support

    ##
    # @api private
    # Defines which read and write functions we expect Array to have.
    module ArrayMethods

      # @api private
      # Read access methods with index parameter
      INDEXED_READ_METHODS = %i[
        [] at fetch include?
      ].freeze

      # @api private
      # All read access methods
      READ_METHODS = INDEXED_READ_METHODS + %i[
        dup first last take drop
      ].freeze

      # @api private
      # Write access methods with index parameter
      INDEXED_WRITE_METHODS = %i[
        []= insert compact
      ].freeze

      # All write access methods
      WRITE_METHODS = INDEXED_WRITE_METHODS + %i[
        unshift pop shift
      ].freeze

    end # module ArrayMethods

  end # module Support

end # module Collapsium
