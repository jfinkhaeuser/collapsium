# collapsium
*Provides various Hash extensions, and an UberHash class that uses them all.*

Ruby's Hash is a pretty nice class, but various extensions are commonly (or not
so commonly) used to make it even more convenient. The most notable would
probably be [ActiveSupport::HashWithIndifferentAccess](http://apidock.com/rails/ActiveSupport/HashWithIndifferentAccess).

That example, unfortunately, has all the problems of requring the kitchen sink
that is ActiveSupport...

[![Gem Version](https://badge.fury.io/rb/collapsium.svg)](https://badge.fury.io/rb/collapsium)
[![Build status](https://travis-ci.org/jfinkhaeuser/collapsium.svg?branch=master)](https://travis-ci.org/jfinkhaeuser/collapsium)
[![Code Climate](https://codeclimate.com/github/jfinkhaeuser/collapsium/badges/gpa.svg)](https://codeclimate.com/github/jfinkhaeuser/collapsium)
[![Test Coverage](https://codeclimate.com/github/jfinkhaeuser/collapsium/badges/coverage.svg)](https://codeclimate.com/github/jfinkhaeuser/collapsium/coverage)

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
- The `PathedAccess` module provides a pathed access method to nested Hashes:

  ```ruby
  x = { "foo" => { "bar" => 42 } }
  x.extend(::Collapsium::PathedAccess)
  x["foo.bar"] # => 42
  ```

Finally, the `UberHash` class just includes all of the above.
