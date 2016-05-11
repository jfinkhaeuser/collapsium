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

    # @return [String] the separator is the character or pattern splitting paths.
    attr_accessor :separator

    # @api private
    # Methods redefined to support pathed read access.
    READ_METHODS = [
      :[], :default, :delete, :fetch, :has_key?, :include?, :key?, :member?,
    ].freeze

    # @api private
    # Methods redefined to support pathed write access.
    WRITE_METHODS = [
      :[]=, :store,
    ].freeze

    # @api private
    # Default path separator
    DEFAULT_SEPARATOR = '.'.freeze

    ##
    # @return [RegExp] the pattern to split paths at; based on `separator`
    def split_pattern
      @separator ||= DEFAULT_SEPARATOR
      /(?<!\\)#{Regexp.escape(@separator)}/
    end

    (READ_METHODS + WRITE_METHODS).each do |method|
      # Wrap all accessor functions to deal with paths
      define_method(method) do |*args, &block|
        # If there are no arguments, there's nothing to do with paths. Just
        # delegate to the hash.
        if args.empty?
          return super(*args, &block)
        end

        # With any of the dispatch methods, we know that the first argument has
        # to be a key. We'll try to split it by the path separator.
        components = args[0].to_s.split(split_pattern)
        loop do
          if components.empty? or not components[0].empty?
            break
          end
          components.shift
        end

        # If there are no components, return self/the root
        if components.empty?
          return self
        end

        # This is already the leaf-most Hash
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
          return super(*copy, &block)
        end

        # Deal with other paths. The frustrating part here is that for nested
        # hashes, only this outermost one is guaranteed to know anything about
        # path splitting, so we'll have to recurse down to the leaf here.
        #
        # For write methods, we need to create intermediary hashes.
        leaf = recursive_fetch(components, self,
                               create: WRITE_METHODS.include?(method))
        if leaf.is_a? Hash
          leaf.default_proc = default_proc
        end
        if leaf.nil?
          leaf = self
        end

        # If we have a leaf, we want to send the requested method to that
        # leaf.
        copy = args.dup
        copy[0] = components.last
        return leaf.send(method, *copy, &block)
      end
    end

    private

    ##
    # Given the path components, recursively fetch any but the last key.
    def recursive_fetch(path, data, options = {})
      # For the leaf element, we do nothing because that's where we want to
      # dispatch to.
      if path.length == 1
        return data
      end

      # Split path into head and tail; for the next iteration, we'll look use only
      # head, and pass tail on recursively.
      head = path[0]
      tail = path.slice(1, path.length)

      # If we're a write function, then we need to create intermediary objects,
      # i.e. what's at head if nothing is there.
      if options[:create] and data[head].nil?
        data[head] = {}
      end

      # Ok, recurse.
      return recursive_fetch(tail, data[head], options)
    end
  end # module PathedAccess
end # module Collapsium
