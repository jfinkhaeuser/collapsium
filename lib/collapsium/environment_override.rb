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

require 'collapsium/recursive_dup'
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
  # be consulted after converting it in the same manner. NOTE:
  # include EnvironmentOverride *after* PathedAccess for both to work well
  # together.
  module EnvironmentOverride
    include ::Collapsium::RecursiveDup

    ##
    # If the module is included, extended or prepended in a class, it'll
    # wrap accessor methods.
    class << self
      include ::Collapsium::Support::HashMethods
      include ::Collapsium::Support::Methods

      ##
      # Returns a proc read access.
      ENV_ACCESS_READER = proc do |wrapped_method, *args, &block|
        # If there are no arguments, there's nothing to do with paths. Just
        # delegate to the hash.
        if args.empty?
          next wrapped_method.call(*args, &block)
        end

        # The method's receiver is encapsulated in the wrapped_method; we'll
        # use it a few times so let's reduce typing. This is essentially the
        # equivalent of `self`.
        receiver = wrapped_method.receiver

        # All KEYED_READ_METHODS have a key as the first argument.
        key = args[0]

        # Grab matching environment variable names. If PathedAccess is
        # supported, we'll try environment variables of the path, starting
        # with the full qualified path and ending with just the last key
        # component.
        env_keys = []
        if receiver.respond_to?(:path_prefix)

          # If we have a prefix, use it.
          components = []
          if not receiver.path_prefix.nil?
            components += receiver.path_components(receiver.path_prefix)
          end

          # The key has its own components. If the key components and prefix
          # components overlap (it happens), ignore the duplication.
          key_comps = receiver.path_components(key.to_s)
          if key_comps.first == components.last
            components.pop
          end
          components += key_comps

          # Start with most qualified, shifting off the first component
          # until we reach just the last component.
          loop do
            path = receiver.normalize_path(components)
            env_keys << path
            components.shift
            if components.empty?
              break
            end
          end
        else
          env_keys = [key.to_s]
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
          parsed = env_value
          begin
            parsed = JSON.parse(env_value)
          rescue JSON::ParserError
            # Do nothing. We just use the env_value verbatim.
          end
          # rubocop:enable Lint/HandleExceptions

          # Excellent, we've got an environment variable. Only use it if it
          # changes something, though. We'll temporarily unset the environment
          # variable while fetching the old value.
          ENV.delete(env_key)
          old_value = receiver[key]
          ENV[env_key] = env_value # not the parsed value!

          if parsed != old_value
            value = parsed
          end
          break
        end

        if not value.nil?
          # We can't just return the value, because that doesn't respect the
          # method being called. We also can't store the value, because that
          # would not reset the Hash after the environment variable was
          # cleared.
          #
          # We can deal with this by duplicating the receiver, writing the value
          # we found into the appropriate key, and then sending the
          # wrapped_method to the duplicate.
          double = receiver.recursive_dup
          double[key] = value
          meth = double.method(wrapped_method.name)
          next meth.call(*args, &block)
        end

        # Otherwise, fall back on the super method.
        next wrapped_method.call(*args, &block)
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
        # Make the capabilities of classes using EnvironmentOverride viral.
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
