I18n Recursive Lookup
=====================

Provides a backend to the i18n gem to allow a definition to contain embedded references to other definitions by introducing the special embedded marker `${}`.

All definitions are lazily evaluated on lookup, and once compiled they're written back to the translation store so that all interpolation happens once.

### Example

    # example.yml
    foo:
        bar: boo
    baz: ${foo.bar}

`I18n.t(:baz)` will correctly evaluate to `boo`.

### Installation

Install the gem either by putting it in your `Gemfile`

    gem 'i18n-recursive-lookup'
or by installing it using rubygems

    gem install i18n-recursive-lookup

Add it to your existing backend by adding these lines to your `config/initializers/i18n.rb` (create one if one doesn't exist):

    # config/initializers/i18n.rb
    require 'i18n/backend/recursive_lookup'
    I18n::Backend::Simple.send(:include, I18n::Backend::RecursiveLookup)

Of course you can replace the `I18n::Backend::Simple` with whatever backend you wish to use.

### TODO
- add detection for infinite embedding cycles