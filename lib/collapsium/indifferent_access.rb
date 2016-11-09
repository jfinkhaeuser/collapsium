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

      READ_METHODS = (
        ::Collapsium::Support::HashMethods::KEYED_READ_METHODS \
        + ::Collapsium::Support::ArrayMethods::INDEXED_READ_METHODS
      ).uniq.freeze

      INDIFFERENT_ACCESS_READER = proc do |wrapped_method, key, *args, &block|
        # Definitely try the key as given first. Then, depending on the key's
        # type and value, we want to try it as a Symbol, String and/or Integer
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

        # With the variations to try assembled, go through them one by one
        result = nil
        receiver = wrapped_method.receiver
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
        # Make the capabilities of classes using PathedAccess viral.
        base.extend(ViralCapabilities)

        # Wrap all accessor functions to deal with paths
        READ_METHODS.each do |method|
          wrap_method(base, method, raise_on_missing: false, &INDIFFERENT_ACCESS_READER)
        end
      end
    end # class << self

  end # module IndifferentAccess

end # module Collapsium
