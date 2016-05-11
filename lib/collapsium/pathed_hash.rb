# coding: utf-8
#
# collapsium
# https://github.com/jfinkhaeuser/collapsium
#
# Copyright (c) 2016 Jens Finkhaeuser and other collapsium contributors.
# All rights reserved.
#

require 'collapsium/recursive_merge'

module Collapsium

  ##
  # The PathedHash class wraps Hash by offering pathed access on top of
  # regular access, i.e. instead of `h["first"]["second"]` you can write
  # `h["first.second"]`.
  #
  # The main benefit is much simpler code for accessing nested structured.
  # For any given path, PathedHash will return nil from `[]` if *any* of
  # the path components do not exist.
  #
  # Similarly, intermediate nodes will be created when you write a value
  # for a path.
  #
  # PathedHash also includes RecursiveMerge.
  class PathedHash
    include RecursiveMerge

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

    ##
    # Initializer. Accepts `nil`, hashes or pathed hashes.
    #
    # @param init [NilClass, Hash] initial values.
    def initialize(init = nil)
      if init.nil?
        @data = {}
      else
        @data = init.dup
      end
      @separator = '.'

      @data.default_proc = DEFAULT_PROC
    end

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

    ##
    # @return [RegExp] the pattern to split paths at; based on `separator`
    def split_pattern
      /(?<!\\)#{Regexp.escape(@separator)}/
    end

    (READ_METHODS + WRITE_METHODS).each do |method|
      # Wrap all accessor functions to deal with paths
      define_method(method) do |*args, &block|
        # If there are no arguments, there's nothing to do with paths. Just
        # delegate to the hash.
        if args.empty?
          return @data.send(method, *args, &block)
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

        # This PathedHash is already the leaf-most Hash
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
          return @data.send(method, *copy, &block)
        end

        # Deal with other paths. The frustrating part here is that for nested
        # hashes, only this outermost one is guaranteed to know anything about
        # path splitting, so we'll have to recurse down to the leaf here.
        #
        # For write methods, we need to create intermediary hashes.
        leaf = recursive_fetch(components, @data,
                               create: WRITE_METHODS.include?(method))
        if leaf.is_a? Hash
          leaf.default_proc = DEFAULT_PROC
        end
        if leaf.nil?
          leaf = @data
        end

        # If we have a leaf, we want to send the requested method to that
        # leaf.
        copy = args.dup
        copy[0] = components.last
        return leaf.send(method, *copy, &block)
      end
    end

    # @return [String] string representation
    def to_s
      @data.to_s
    end

    # @return [PathedHash] duplicate, as `.dup` usually works
    def dup
      PathedHash.new(@data.dup)
    end

    # In place merge, as it usually works for hashes.
    # @return [PathedHash] self
    def merge!(*args, &block)
      # FIXME: we may need other methods like this. This is used by
      #        RecursiveMerge, so we know it's required.
      PathedHash.new(super)
    end

    ##
    # Map any missing method to the Hash implementation
    def respond_to_missing?(meth, include_private = false)
      if not @data.nil? and @data.respond_to?(meth, include_private)
        return true
      end
      return super
    end

    ##
    # Map any missing method to the Hash implementation
    def method_missing(meth, *args, &block)
      if not @data.nil? and @data.respond_to?(meth)
        return @data.send(meth.to_s, *args, &block)
      end
      return super
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
  end # class PathedHash
end # module Collapsium
