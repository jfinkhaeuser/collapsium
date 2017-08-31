# coding: utf-8
#
# collapsium
# https://github.com/jfinkhaeuser/collapsium
#
# Copyright (c) 2016-2017 Jens Finkhaeuser and other collapsium contributors.
# All rights reserved.
#

require 'collapsium/support/hash_methods'
require 'collapsium/support/methods'
require 'collapsium/support/path_components'

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

    include ::Collapsium::Support::PathComponents

    ##
    # If the module is included, extended or prepended in a class, it'll
    # wrap accessor methods.
    class << self
      include ::Collapsium::Support::Methods

      # We want to wrap methods for Arrays and Hashes alike
      READ_METHODS = (
        ::Collapsium::Support::HashMethods::KEYED_READ_METHODS \
        + ::Collapsium::Support::ArrayMethods::INDEXED_READ_METHODS
      ).uniq.freeze
      WRITE_METHODS = (
        ::Collapsium::Support::HashMethods::KEYED_WRITE_METHODS \
        + ::Collapsium::Support::ArrayMethods::INDEXED_WRITE_METHODS
      ).uniq.freeze

      ##
      # Returns a proc for either read or write access. Procs for write
      # access will create intermediary hashes when e.g. setting a value for
      # `foo.bar.baz`, and the `bar` Hash doesn't exist yet.
      def create_proc(write_access)
        return proc do |wrapped_method, *args, &block|
          # If there are no arguments, there's nothing to do with paths. Just
          # delegate to the hash.
          if args.empty?
            next wrapped_method.call(*args, &block)
          end

          # The method's receiver is encapsulated in the wrapped_method; we'll
          # use it a few times so let's reduce typing. This is essentially the
          # equivalent of `self`.
          receiver = wrapped_method.receiver

          # With any of the dispatch methods, we know that the first argument has
          # to be a key. We'll try to split it by the path separator.
          components = receiver.path_components(args[0].to_s)

          # If there are no components, return the receiver itself/the root
          if components.empty?
            next receiver
          end

          # Try to find the leaf, based on the given components.
          leaf = recursive_fetch(components, receiver, [], create: write_access)

          # Since Methods already contains loop prevention and we may want to
          # call wrapped methods, let's just find the method to call from the
          # leaf by name.
          meth = leaf.method(wrapped_method.name)

          # If the first argument was a symbol key, we want to use it verbatim.
          # Otherwise we had pathed access, and only want to pass the last
          # component to whatever method we're calling.
          the_args = args
          if not args[0].is_a?(Symbol) and args[0] != components.last
            the_args = args.dup
            the_args[0] = components.last
          end

          # Array methods we're modifying here are indexed, so the first argument
          # must be an integer. Let's make it so :)
          if leaf.is_a? Array and the_args[0][0] =~ /[0-9]/
            the_args = the_args.dup
            the_args[0] = the_args[0].to_s.to_i
          end

          # Then we can continue with that method.
          result = meth.call(*the_args, &block)

          # Sadly, we can't just return the result and be done with it.
          # We need to tell the virality function (below) what we know about the
          # result's path prefix, so we enhance the result value explicitly here.
          result_path = receiver.path_components(receiver.path_prefix)
          result_path += components
          next ViralCapabilities.enhance_value(leaf, result, result_path)
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
        READ_METHODS.each do |method|
          wrap_method(base, method, raise_on_missing: false, &PATHED_ACCESS_READER)
        end
        WRITE_METHODS.each do |method|
          wrap_method(base, method, raise_on_missing: false, &PATHED_ACCESS_WRITER)
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
    # Ensure that all values have their path_prefix set.
    def virality(value, *args)
      # Figure out what path prefix to set on the value, if any.
      # Candidates for the prefix are:
      explicit = args[0] || []
      from_self = path_components(path_prefix)
      from_value = path_components(value.path_prefix)

      prefix = []
      if not explicit.empty?
        # If we got explicit information, we most likely want to use that.
        prefix = explicit
      elsif not from_self.empty?
        # If we got information from self, that's the next best candidate.
        prefix = from_self
      end

      # However, if the value already has a better path prefix than either
      # of the above, we want to keep that.
      if prefix.length > from_value.length
        value.path_prefix = normalize_path(prefix)
      end

      return value
    end

  end # module PathedAccess
end # module Collapsium
