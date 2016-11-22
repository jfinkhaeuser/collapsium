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
  # Provides indifferent access to string/symbol keys in a Hash. That is,
  # if your hash contains a string key, you can also access it via a symbol
  # and vice versa.
  module IndifferentAccess

    ##
    # If the module is included, extended or prepended in a class, it'll
    # wrap accessor methods.
    class << self
      include ::Collapsium::Support::Methods

      ##
      # Given a key, returns all indifferent permutations to try.
      def key_permutations(key)
        tries = [key]
        if key.is_a? Symbol
          key_s = key.to_s
          tries << key_s
          if key_s =~ /^[0-9]/
            tries << key_s.to_i
          end
        elsif key.is_a? String
          tries << key.to_sym
          if key =~ /^[0-9]/
            tries << key.to_i
          end
        elsif key.is_a? Integer
          tries += [key.to_s, key.to_s.to_sym]
        end

        return tries
      end

      ##
      # Make the given keys unique according to the logic of this module.
      def unique_keys(keys)
        # The simplest way is to stringify all keys before making them
        # unique. That works for Integer as well as Symbol.
        return keys.map(&:to_s).uniq
      end

      ##
      # Sort the given keys indifferently. This will sort Integers first,
      # Symbols second and Strings third. Everything else comes last. This
      # is done because that's the order in which comparsion time increases.
      def sorted_keys(keys, &block)
        # Sorting sucks because we can't compare Strings and Symbols. So in
        # order to get this right, we'll have to sort each type individually,
        # then concatenate the results.
        sorted = []
        [Integer, Symbol, String].each do |klass|
          sorted += keys.select { |key| key.is_a?(klass) }.sort(&block)
        end
        return sorted
      end

      READ_METHODS = (
          ::Collapsium::Support::HashMethods::KEYED_READ_METHODS \
          + ::Collapsium::Support::HashMethods::KEYED_WRITE_METHODS
      ).freeze

      INDIFFERENT_ACCESS_READER = proc do |wrapped_method, *args, &block|
        # Bail out early if the receiver is not a Hash. Do the same if we have
        # no key.
        receiver = wrapped_method.receiver
        if not receiver.is_a? Hash or args.empty?
          next wrapped_method.call(*args, &block)
        end

        # Definitely try the key as given first. Then, depending on the key's
        # type and value, we want to try it as a Symbol, String and/or Integer
        key = args.shift
        tries = IndifferentAccess.key_permutations(key)

        # With the variations to try assembled, go through them one by one
        result = nil
        tries.each do |try|
          if receiver.keys.include?(try)
            result = wrapped_method.call(try, *args, &block)
            break
          end
        end

        # If any of the above yielded a result, great, return that. Otherwise
        # yield to the default implementation (i.e. wrapped_method).
        if not result.nil?
          next result
        end
        next wrapped_method.call(key, *args, &block)
      end.freeze

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
        # Make the capabilities of classes using IndifferentAccess viral.
        base.extend(ViralCapabilities)

        # Wrap all accessor functions to deal with paths
        READ_METHODS.each do |method|
          wrap_method(base, method, raise_on_missing: false,
                      &INDIFFERENT_ACCESS_READER)
        end
      end
    end # class << self

  end # module IndifferentAccess

end # module Collapsium
