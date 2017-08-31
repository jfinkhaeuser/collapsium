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
    # Large negative integer for failures we can't express otherwise in scoring.
    FAILURE = -2147483648

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
      return prototype_match_score(prototype, strict).positive?
    end

    ##
    # Calculates a matching score for matching the prototype. A score of 0 or
    # less is not a match, and the higher the score, the better the match is.
    #
    # @param prototype (Hash) The prototype to match against.
    # @param strict (Boolean) If true, this Hash may not contain keys that are
    #     not present in the prototype.
    # @return (Integer) Greater than zero for positive matches, equal to or
    #     less than zero for mismatches.
    def prototype_match_score(prototype, strict = false)
      # The prototype contains keys that are not in the Hash. That's a failure,
      # and the level of failure is the number of missing keys.
      missing = (prototype.keys - keys).length
      if missing.positive?
        return -missing
      end

      # In strict evaluation, the Hash may also not contain keys that are not
      # in the prototoype.
      if strict
        missing = (keys - prototype.keys).length
        if missing.positive?
          return -missing
        end
      end

      # Now we have to examine the prototype's values.
      score = 0
      prototype.each do |key, value|
        # We can skip any nil values in the prototype. They exist only to ensure
        # the key is present. We do increase the score for a matched key, though!
        if value.nil?
          score += 1
          next
        end

        # If the prototype value is a Hash, then the Hash value also has to be,
        # and we have to recurse into this Hash.
        if value.is_a?(Hash)
          if not self[key].is_a?(Hash)
            return FAILURE
          end

          self[key].extend(PrototypeMatch)
          recurse_score = self[key].prototype_match_score(value)
          if recurse_score.negative?
            return recurse_score
          end
          score += recurse_score

          next
        end

        # Otherwise the prototype value must be equal to the Hash's value
        if self[key] == value
          score += 1
        else
          score -= 1
        end
      end

      # Return score
      return score
    end
  end # module PrototypeMatch
end # module Collapsium
