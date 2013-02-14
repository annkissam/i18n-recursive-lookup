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

### TODO
- add detection for infinite embedding cycles