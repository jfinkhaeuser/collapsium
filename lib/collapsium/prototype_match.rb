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
  # Provides prototype matching for Hashes. See #prototype_match
  module PrototypeMatch
    ##
    # Given a prototype Hash, returns true if (recursively):
    # - this hash contains all the prototype's keys, and
    # - this hash contains all the prototype's values
    # Note that this is not the same as equality. If the prototype provides a
    # nil value for any key, then any value in this Hash is considered to be
    # valid.
    # @param prototype (Hash) The prototype to match against.
    # @param strict (Boolean) If true, this Hash may not contain keys that are
    #     not present in the prototype.
    # @return (Boolean) True if matching succeeds, false otherwise.
    def prototype_match(prototype, strict = false)
      # Prototype contains keys not in the Hash,so that's a failure.
      if not (prototype.keys - keys).empty?
        return false
      end

      # In strict evaluation, the Hash may also not contain keys that are not
      # in the prototoype.
      if strict and not (keys - prototype.keys).empty?
        return false
      end

      # Now we have to examine the prototype's values.
      prototype.each do |key, value|
        # We can skip any nil values in the prototype. They exist only to ensure
        # the key is present.
        if value.nil?
          next
        end

        # If the prototype value is a Hash, then the Hash value also has to be,
        # and we have to recurse into this Hash.
        if value.is_a?(Hash)
          if not self[key].is_a?(Hash)
            return false
          end

          self[key].extend(PrototypeMatch)
          if not self[key].prototype_match(value)
            return false
          end

          next
        end

        # Otherwise the prototype value must be equal to the Hash's value
        if self[key] != value
          return false
        end
      end

      # All other cases must be true.
      return true
    end
  end # module PrototypeMatch
end # module Collapsium
