require 'test_helper'

class I18nBackendRecursiveLookupTest < Test::Unit::TestCase
  class Backend < I18n::Backend::Simple
    include I18n::Backend::RecursiveLookup
  end

  def setup
    I18n.backend = Backend.new
    I18n.backend.store_translations(:en,
                                    foo: 'foo',
                                    bar: {
                                      baz: 'bar ${foo}',
                                      boo: {
                                        baz: 'hoo ${bar.baz}'
                                      }
                                    },
                                    alternate_lookup: '${baz}',
                                    hash_lookup: '${hash}',
                                    hash: {
                                      one: 'hash',
                                      other: 'hashes',
                                      deeper: {
                                        first: 'First hash',
                                        second: 'Second hash'
                                      }
                                    },
                                    hash_lookup_no_deeper: {
                                      one: 'hash no deep',
                                      other: 'hashes no deep'
                                    },
                                    number_hash: {
                                      format: {
                                        delimiter: ',',
                                        precision: 3,
                                        significant: false
                                      }
                                    })
  end

  def teardown
    I18n.backend = nil
  end

  test 'still returns an existing translation as usual' do
    assert_equal 'foo', I18n.t(:foo)
  end

  test 'still fails for a missing key' do
    assert_equal 'translation missing: en.missing_key', I18n.t(:missing_key)
  end

  test 'does a lookup on an embedded key' do
    assert_equal 'bar foo', I18n.t(:'bar.baz')
    assert_equal 'hoo bar foo', I18n.t(:'bar.boo.baz')
  end

  test 'stores a compiled lookup' do
    original_lookup = I18n::Backend::Simple.instance_method(:lookup).bind(I18n.backend)

    result = I18n.t(:'bar.baz')
    precompiled_result = original_lookup.call(:en, :'bar.baz')
    assert_equal result, precompiled_result
  end

  test 'resolves hash lookups' do
    assert_equal I18n.t(:'bar.boo').to_s, '{:baz=>"hoo bar foo"}'
  end

  test 'handles non-string results from lookup' do
    assert_equal '{:delimiter=>",", :precision=>3, :significant=>false}',
                 I18n.t(:'number_hash.format', locale: :en, default: {}).to_s
  end

  test 'stores a compiled hash lookup' do
    original_lookup = I18n::Backend::Simple.instance_method(:lookup).bind(I18n.backend)

    result = I18n.t(:'bar.boo')
    precompiled_result = original_lookup.call(:en, :'bar.boo')
    assert_equal result, precompiled_result
  end

  test 'correctly returns a hash' do
    result = I18n.t(:hash_lookup)

    assert_equal Hash, result.class

    assert_equal({
                   one: 'hash',
                   other: 'hashes',
                   deeper: {
                     first: 'First hash',
                     second: 'Second hash'
                   }
                 }, result)
  end

  test 'correctly translates a hash reference with count' do
    assert_equal 'hashes no deep', I18n.t(:hash_lookup_no_deeper, count: 5)
  end

  test 'correctly fails for a hash reference that is not present' do
    assert_equal 'translation missing: en.hash_lookup.deeper.not_there.really',
                 I18n.t(:'hash_lookup.deeper.not_there.really')
  end
end

class I18nBackendRecursiveLookupWithoutCacheTest < Test::Unit::TestCase
  class Backend < I18n::Backend::Simple
    include I18n::Backend::RecursiveLookup
  end

  def setup
    I18n.backend = Backend.new
    I18n.backend.disable_interpolation_cache
    I18n.backend.store_translations(:en,
                                    foo: 'foo',
                                    bar: {
                                      baz: 'bar ${foo}',
                                      boo: {
                                        baz: 'hoo ${bar.baz}'
                                      }
                                    })
  end

  def teardown
    I18n.backend = nil
  end

  test 'recursive translation of a hash with cache disabled' do
    assert_equal({
                   baz: 'bar foo',
                   boo: {
                     baz: 'hoo bar foo'
                   }
                 }, I18n.t(:bar))

    assert_equal({
                   baz: 'bar ${foo}',
                   boo: {
                     baz: 'hoo ${bar.baz}'
                   }
                 }, I18n.backend.send(:translations)[:en][:bar])
  end

  test 'recursive translation of a string with cache disabled' do
    assert_equal 'bar foo', I18n.t(:'bar.baz')
    assert_equal 'bar ${foo}', I18n.backend.send(:translations)[:en][:bar][:baz]
  end

  test 'correctly reevaluates translations' do
    assert_equal 'bar foo', I18n.t(:'bar.baz')

    I18n.backend.store_translations(:en,
                                    foo: 'new_foo')

    assert_equal 'bar new_foo', I18n.t(:'bar.baz')
  end
end

class I18nBackendRecursiveLookupWithoutCacheAndFallbacksTest < Test::Unit::TestCase
  class Backend < I18n::Backend::Simple
    include I18n::Backend::Fallbacks
    include I18n::Backend::RecursiveLookup
  end

  def setup
    I18n.backend = Backend.new
    I18n.available_locales = %w[en en-cl]
    I18n.fallbacks = ['en']
    I18n.default_locale = 'en'
    I18n.locale = 'en-cl'
    I18n.backend.disable_interpolation_cache
    I18n.backend.store_translations('en',
                                    foo: 'foo',
                                    bar: {
                                      baz: 'bar ${foo}',
                                      boo: {
                                        baz: 'hoo ${bar.baz}'
                                      }
                                    })
    I18n.backend.store_translations('en-cl',
                                    foo: 'foo-cl')
  end

  def teardown
    I18n.backend = nil
    I18n.locale = 'en'
  end

  # When translating I18n.t(:bar) with es-cl, the referenced translation 'foo' needs to be translated to 'foo-cl' and not 'foo'
  test 'if referenced translation is in the current locale, get that one instead of the current one from the fallback when translating a key that has a hash' do
    assert_equal({
                   baz: 'bar foo-cl',
                   boo: {
                     baz: 'hoo bar foo-cl'
                   }
                 }, I18n.t(:bar))

    assert_equal({
                   baz: 'bar ${foo}',
                   boo: {
                     baz: 'hoo ${bar.baz}'
                   }
                 }, I18n.backend.send(:translations)[:en][:bar])
  end

  test 'if referenced translation is in the current locale, get that one instead of the current one from the fallback when translating a string' do
    assert_equal 'bar foo-cl', I18n.t(:'bar.baz')
    assert_equal 'bar ${foo}', I18n.backend.send(:translations)[:en][:bar][:baz]
  end
end
