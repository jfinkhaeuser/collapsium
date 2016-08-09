# coding: utf-8
#
# collapsium
# https://github.com/jfinkhaeuser/collapsium
#
# Copyright (c) 2016 Jens Finkhaeuser and other collapsium contributors.
# All rights reserved.
#

require 'collapsium/support/hash_methods'

module Collapsium

  ##
  # The PathedAccess module can be used to extend Hash with pathed access
  # on top of regular access, i.e. instead of `h["first"]["second"]` you can
  # write `h["first.second"]`.
  #
  # The main benefit is much simpler code for accessing nested structured.
  # For any given path, PathedAccess will return nil from `[]` if *any* of
  # the path components do not exist.
  #
  # Similarly, intermediate nodes will be created when you write a value
  # for a path.
  module PathedAccess

    include ::Collapsium::Support::HashMethods

    # @return [String] the separator is the character or pattern splitting paths.
    def separator
      @separator ||= DEFAULT_SEPARATOR
      return @separator
    end

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

    (READ_METHODS + WRITE_METHODS).each do |method|
      # Wrap all accessor functions to deal with paths
      define_method(method) do |*args, &block|
        # If there are no arguments, there's nothing to do with paths. Just
        # delegate to the hash.
        if args.empty?
          return fixup_hashlike(super(*args, &block))
        end

        # With any of the dispatch methods, we know that the first argument has
        # to be a key. We'll try to split it by the path separator.
        components = path_components(args[0].to_s)

        # If there are no components, return self/the root
        if components.empty?
          return self
        end

        # This is already the leaf-most entry
        if components.length == 1
          # Weird edge case: if we didn't have to shift anything, then it's
          # possible we inadvertently changed a symbol key into a string key,
          # which could mean looking fails.
          # We can detect that by comparing copy[0] to a symbolized version of
          # components[0].
          copy = args.dup
          if copy[0] != components[0].to_sym
            copy[0] = components[0]
          end

          return fixup_hashlike(super(*copy, &block), join_path(components))
        end

        # Deal with other paths. The frustrating part here is that for nested
        # hashes, only this outermost one is guaranteed to know anything about
        # path splitting, so we'll have to recurse down to the leaf here.
        #
        # For write methods, we need to create intermediary hashes.
        leaf = recursive_fetch(components, self, [],
                               create: WRITE_METHODS.include?(method))

        # If we have a leaf, we want to send the requested method to that
        # leaf.
        copy = args.dup
        copy[0] = components.last
        return fixup_hashlike(leaf.send(method, *copy, &block),
                              join_path(components))
      end
    end

    ##
    # Break path into components. Expects a String path separated by the
    # `#separator`, and returns the path split into components (an Array of
    # String).
    def path_components(path)
      components = path.split(split_pattern)
      components.select! { |c| not c.nil? and not c.empty? }
      return components
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
      return separator + join_path(path_components(path))
    end

    private

    ##
    # Given the path components, recursively fetch any but the last key.
    def recursive_fetch(path, data, current_path = [], options = {})
      # For the leaf element, we do nothing because that's where we want to
      # dispatch to.
      if path.length == 1
        return fixup_hashlike(data, join_path(current_path))
      end

      # Split path into head and tail; for the next iteration, we'll look use only
      # head, and pass tail on recursively.
      head = path[0]
      current_path << head
      tail = path.slice(1, path.length)

      # If we're a write function, then we need to create intermediary objects,
      # i.e. what's at head if nothing is there.
      if data[head].nil?
        # If the head is nil, we can't recurse. In create mode that means we
        # want to create hash children, but in read mode we're done recursing.
        # By returning a hash here, we allow the caller to send methods on to
        # this temporary, making a PathedAccess Hash act like any other Hash.
        if not options[:create]
          return fixup_hashlike({}, join_path(current_path))
        end

        data[head] = fixup_hashlike({}, join_path(current_path))
      end

      # Ok, recurse.
      return recursive_fetch(tail, data[head], current_path, options)
    end

    ##
    # Make a Hash-like object (if given) appear as much as this Hash-like
    # object as possible.
    def fixup_hashlike(value, path_prefix = nil)
      # If it's not a Hash, return it unaltered.
      if not value.is_a? Hash
        return value
      end

      # If it's a Hash, but not a Hash of this particular class, then make it
      # a Hash of this class.
      if value.class != self.class
        new_value = self.class.new
        new_value.merge!(value)
        value = new_value
      end

      # Extend all modules extended in self.
      value_mods = (class << value; self end).included_modules
      own_mods = (class << self; self end).included_modules
      (own_mods - value_mods).each do |mod|
        value.extend(mod)
      end

      # Set the default proc to our own value.
      value.default_proc = default_proc

      # Finally, if it responds to a path_prefix variable, set the path
      # prefix.
      if not path_prefix.nil? and value.respond_to?(:path_prefix)
        value.path_prefix = path_prefix
      end

      return value
    end
  end # module PathedAccess
end # module Collapsium
