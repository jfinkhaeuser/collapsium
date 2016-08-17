# coding: utf-8
#
# collapsium
# https://github.com/jfinkhaeuser/collapsium
#
# Copyright (c) 2016 Jens Finkhaeuser and other collapsium contributors.
# All rights reserved.
#

require 'collapsium/support/hash_methods'
require 'collapsium/support/methods'

require 'collapsium/viral_capabilities'

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

    ##
    # If the module is included, extended or prepended in a class, it'll
    # wrap accessor methods.
    class << self
      include ::Collapsium::Support::HashMethods
      include ::Collapsium::Support::Methods

      ##
      # Returns a proc for either read or write access. Procs for write
      # access will create intermediary hashes when e.g. setting a value for
      # `foo.bar.baz`, and the `bar` Hash doesn't exist yet.
      def create_proc(write_access)
        return proc do |super_method, *args, &block|
          # If there are no arguments, there's nothing to do with paths. Just
          # delegate to the hash.
          if args.empty?
            next super_method.call(*args, &block)
          end

          # The method's receiver is encapsulated in the super_method; we'll
          # use it a few times so let's reduce typing. This is essentially the
          # equivalent of `self`.
          receiver = super_method.receiver

          # With any of the dispatch methods, we know that the first argument has
          # to be a key. We'll try to split it by the path separator.
          components = receiver.path_components(args[0].to_s)

          # If there are no components, return the receiver itself/the root
          if components.empty?
            next receiver
          end

          # Try to find the leaf, based on the given components.
          leaf = recursive_fetch(components, receiver, [], create: write_access)

          # The tricky part is what to do with the leaf.
          meth = nil
          if receiver.object_id == leaf.object_id
            # a) if the leaf and the receiver are identical, then the receiver
            #    itself was requested, and we really just need to delegate to its
            #    super_method.
            meth = super_method
          else
            # b) if the leaf is different from the receiver, we want to delegate
            #    to the leaf.
            meth = leaf.method(super_method.name)
          end

          # If the first argument was a symbol key, we want to use it verbatim.
          # Otherwise we had pathed access, and only want to pass the last
          # component to whatever method we're calling.
          the_args = args
          if not args[0].is_a?(Symbol)
            the_args = args.dup
            the_args[0] = components.last
          end

          # Then we can continue with that method.
          next meth.call(*the_args, &block)
        end # proc
      end # create_proc

      # Create a reader and write proc, because we only know
      PATHED_ACCESS_READER = PathedAccess.create_proc(false).freeze
      PATHED_ACCESS_WRITER = PathedAccess.create_proc(true).freeze

      def included(base)
        enhance(base)
      end

      def extended(base)
        enhance(base)
      end

      def prepended(base)
        enhance(base)
      end

      def enhance(base)
        # Make the capabilities of classes using PathedAccess viral.
        base.extend(ViralCapabilities)

        # Wrap all accessor functions to deal with paths
        KEYED_READ_METHODS.each do |method|
          wrap_method(base, method, &PATHED_ACCESS_READER)
        end
        KEYED_WRITE_METHODS.each do |method|
          wrap_method(base, method, &PATHED_ACCESS_WRITER)
        end
      end

      ##
      # Given the path components, recursively fetch any but the last key.
      def recursive_fetch(path, data, current_path = [], options = {})
        # Split path into head and tail; for the next iteration, we'll look use
        # only head, and pass tail on recursively.
        head = path[0]
        current_path << head
        tail = path.slice(1, path.length)

        # We know that the data has the current path. We also know that thanks to
        # virality, data will respond to :path_prefix. So we might as well set the
        # path, as long as it is more specific than what was previously there.
        current_normalized = data.normalize_path(current_path)
        if current_normalized.length > data.path_prefix.length
          data.path_prefix = current_normalized
        end

        # For the leaf element, we do nothing because that's where we want to
        # dispatch to.
        if path.length == 1
          return data
        end

        # If we're a write function, then we need to create intermediary objects,
        # i.e. what's at head if nothing is there.
        if data[head].nil?
          # If the head is nil, we can't recurse. In create mode that means we
          # want to create hash children, but in read mode we're done recursing.
          # By returning a hash here, we allow the caller to send methods on to
          # this temporary, making a PathedAccess Hash act like any other Hash.
          if not options[:create]
            return {}
          end

          data[head] = {}
        end

        # Ok, recurse.
        return recursive_fetch(tail, data[head], current_path, options)
      end
    end # class << self

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

    ##
    # Ensure that all values have their path_prefix set.
    def virality(value)
      # If a value was set via a nested Hash, it may not have got its
      # path_prefix set during storing (i.e. x[key] = { nested: some_hash }
      # In that case, we do always know that the value's path prefix is the same
      # as the receiver.
      value.path_prefix = path_prefix
      return value
    end

  end # module PathedAccess
end # module Collapsium
