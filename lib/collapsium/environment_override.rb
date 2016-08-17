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
  # The EnvironmentOverride module wraps read access methods to return
  # the contents of environment variables derived from the key instead of
  # the value contained in the Hash.
  #
  # The environment variable to use is derived from the key by replacing
  # all consecutive occurrences of non-alphanumeric characters with an
  # underscore (_), and converting the alphabetic characters to upper case.
  # Leading and trailing underscores will be stripped.
  #
  # For example, the key "some!@email.org" will become "SOME_EMAIL_ORG".
  #
  # If PathedAccess is also used, the :path_prefix of nested hashes will
  # be consulted after converting it in the same manner.
  module EnvironmentOverride
    ##
    # If the module is included, extended or prepended in a class, it'll
    # wrap accessor methods.
    class << self
      include ::Collapsium::Support::HashMethods
      include ::Collapsium::Support::Methods

      ##
      # Returns a proc read access.
      ENV_ACCESS_READER = proc do |super_method, *args, &block|
        # If there are no arguments, there's nothing to do with paths. Just
        # delegate to the hash.
        if args.empty?
          next super_method.call(*args, &block)
        end

        # The method's receiver is encapsulated in the super_method; we'll
        # use it a few times so let's reduce typing. This is essentially the
        # equivalent of `self`.
        receiver = super_method.receiver

        # All KEYED_READ_METHODS have a key as the first argument.
        key = args[0]

        # Grab matching environment variable names. We consider first a pathed
        # name, if pathed access is supported, followed by the unpathed name.
        env_keys = [key.to_s]
        if receiver.respond_to?(:path_prefix) and not
            (receiver.path_prefix.nil? or receiver.path_prefix.empty?)
          prefix_components = receiver.path_components(receiver.path_prefix)

          if prefix_components.last == key
            env_keys.unshift(receiver.path_prefix)
          else
            env_keys.unshift(receiver.path_prefix + receiver.separator + key.to_s)
          end
        end
        env_keys.map! { |k| receiver.key_to_env(k) }
        env_keys.select! { |k| not k.empty? }
        env_keys.uniq!

        # When we have the keys (in priority order), try to see if the
        # environment yields something useful.
        value = nil
        env_keys.each do |env_key|
          # Grab the environment value; skip if there's nothing there.
          env_value = ENV[env_key]
          if env_value.nil?
            next
          end

          # If the environment variable parses as JSON, that's great, we'll use
          # the parsed result. Otherwise use it as a string.
          require 'json'
          # rubocop:disable Lint/HandleExceptions
          begin
            env_value = JSON.parse(env_value)
          rescue JSON::ParserError
            # Do nothing. We just use the env_value verbatim.
          end
          # rubocop:enable Lint/HandleExceptions

          # For the given key, retrieve the current value. We'll need it later.
          # Note that we deliberately do not use any of KEYED_READ_METHODS,
          # because that would recurse infinitely.
          old_value = nil
          receiver.each do |k, v|
            if k == key
              old_value = v
              break
            end
          end

          # Note that we re-assign the value only if it's changed, but we
          # break either way. If env_value exists, it must be used, but
          # changing it always will lead to an infinite recursion.
          # The double's super_method will never be called, but rather
          # always this wrapper.
          if env_value != old_value
            value = env_value
          end
          break
        end
        if not value.nil?
          # We can't just return the value, because that doesn't respect the
          # method being called. We can deal with this by duplicating the
          # receiver, writing the value we found into the appropriate key,
          # and then sending the super_method to the duplicate.
          double = receiver.dup
          double[key] = value
          meth = double.method(super_method.name)
          next meth.call(*args, &block)
        end

        # Otherwise, fall back on the super method.
        next super_method.call(*args, &block)
      end.freeze # proc

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

        # Wrap read accessor functions to deal with paths
        KEYED_READ_METHODS.each do |method|
          wrap_method(base, method, &ENV_ACCESS_READER)
        end
      end
    end # class << self

    def key_to_env(key)
      # First, convert to upper case
      env_key = key.upcase

      # Next, replace non-alphanumeric characters to underscore. This also
      # collapses them into a single undescore.
      env_key.gsub!(/[^[:alnum:]]+/, '_')

      # Strip leading and trailing underscores.
      env_key.gsub!(/^_*(.*?)_*$/, '\1')

      return env_key
    end
  end # module EnvironmentOverride
end # module Collapsium
