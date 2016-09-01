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
    # Defines functions for path prefixes and components. This is mainly used
    # by PathedAccess, but it helps keeping everything separate so that
    # ViralCapabilities can also apply it to Arrays.
    module PathComponents

      ##
      # Assume any pathed access has this prefix.
      def path_prefix=(value)
        @path_prefix = normalize_path(value)
      end

      def path_prefix
        @path_prefix ||= ''
        return @path_prefix
      end

      # @api private
      # Default path separator
      DEFAULT_SEPARATOR = '.'.freeze

      ##
      # @return [RegExp] the pattern to split paths at; based on `separator`
      def split_pattern
        /(?<!\\)#{Regexp.escape(separator)}/
      end

      # @return [String] the separator is the character or pattern splitting paths.
      def separator
        @separator ||= DEFAULT_SEPARATOR
        return @separator
      end

      ##
      # Break path into components. Expects a String path separated by the
      # `#separator`, and returns the path split into components (an Array of
      # String).
      def path_components(path)
        return filter_components(path.split(split_pattern))
      end

      ##
      # Given path components, filters out unnecessary ones.
      def filter_components(components)
        return components.select { |c| not c.nil? and not c.empty? }
      end

      ##
      # Join path components with the `#separator`.
      def join_path(components)
        return components.join(separator)
      end

      ##
      # Normalizes a String path so that there are no empty components, and it
      # starts with a separator.
      def normalize_path(path)
        components = []
        if path.respond_to?(:split) # likely a String
          components = path_components(path)
        elsif path.respond_to?(:join) # likely an Array
          components = filter_components(path)
        end
        return separator + join_path(components)
      end

    end # module PathComponents

  end # module Support

end # module Collapsium
