# collapsium
*Provides various Hash and Array extensions, and an UberHash class that uses them all.*

Ruby's Hash is a pretty nice class, but various extensions are commonly (or not
so commonly) used to make it even more convenient. The most notable would
probably be [ActiveSupport::HashWithIndifferentAccess](http://apidock.com/rails/ActiveSupport/HashWithIndifferentAccess).

That example, unfortunately, has all the problems of requring the kitchen sink
that is ActiveSupport...

[![Gem Version](https://badge.fury.io/rb/collapsium.svg)](https://badge.fury.io/rb/collapsium)
[![Build status](https://travis-ci.org/jfinkhaeuser/collapsium.svg?branch=master)](https://travis-ci.org/jfinkhaeuser/collapsium)

# Functionality

- The `IndifferentAccess` module provides support for indifferent access via a
  `#default_proc`:

  ```ruby
  x = { foo: 42 }
  x.default_proc = ::Collapsium::IndifferentAccess::DEFAULT_PROC
  x['foo'] # => 42
  ```
- The `RecursiveMerge` module provides a `#recursive_merge` function which merges
  Hashes recursively:

  ```ruby
  x = { foo: { bar: 42 } }
  x.extend(::Collapsium::RecursiveMerge)
  x.recursive_merge(foo: { baz: 'quux' })
  # => {
  #   foo: {
  #     bar: 42,
  #     baz: 'quux',
  #   },
  # }
  ```
- The `RecursiveDup` module provides a `#recursive_dup` function which `#dup`s
  recursively.
- The `RecursiveSort` module provides a `#recursive_sort` function which sorts
  recursively.
- The `RecursiveFetch` module provides `#recursve_fetch` and `#recursive_fetch_one`
  which searches recursively for all/the first ocurrence(s) of a key respectively.
- The `PathedAccess` module provides a pathed access method to nested Hashes:

  ```ruby
  x = { "foo" => { "bar" => 42 } }
  x.extend(::Collapsium::PathedAccess)
  x["foo.bar"] # => 42
  ```
- The `PrototypeMatch` module provides the ability to match nested structures
  by prototype:

  ```ruby
  x = { "foo" => { "bar" => 42 } }
  x.extend(::Collapsium::PrototypeMatch)
  x.prototype_match("foo" => { "bar" => nil }}) # => true
  ```

  Prototypes can include values, in which case they need to match. Or they can
  contain nil, in which case any value will match, but the associated key must
  still exist in the receiver.
- Finally, the `ViralCapabilities` module is included in many of the above,
  and ensures that nested structures retain the capabilites of their parents:

  ```ruby
  x = { "foo" => { "bar" => 42 } }
  x.extend(::Collapsium::PathedAccess)
  x.path_prefix # => "." (part of PathedAccess)
  x["foo"].path_prefix # => ".foo" (virally inherited)
  ```

Finally, the `UberHash` class just includes all of the above.

- The `EnvironmentOverride` method allows you to override keys in a nested
  structure with environment variables:

  ```ruby
  x = ::Collapsium::UberHash.new
  x.extend(::Collapsium::EnvironmentOverride)

  x["foo.bar"] = 42
  ENV["FOO_BAR"] = "override"
  x["foo.bar"] # => "override"
  ```

  Note that `EnvironmentOverride` is not included in `UberHash` by default.
  It just messes with the predictability of the class too much. However, the
  [collapsium-config](https://github.com/jfinkhaeuser/collapsium-config) gem
  uses it extensively to provide easy overrides for configuration values.
