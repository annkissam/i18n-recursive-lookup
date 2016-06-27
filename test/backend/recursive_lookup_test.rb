require 'test_helper'

class I18nBackendRecursiveLookupTest < Test::Unit::TestCase
  class Backend < I18n::Backend::Simple
    include I18n::Backend::RecursiveLookup
  end

  def setup
    I18n.backend = Backend.new
    I18n.backend.store_translations(:en,
      :foo => 'foo',
      :bar => {
        :baz => 'bar ${foo}',
        :boo => {
          :baz => 'hoo ${bar.baz}'
        }
      },
      :alternate_lookup => '${baz}',
      :hash_lookup => '${hash}',
      :hash => {
        one: 'hash',
        other: 'hashes',
        deeper: {
          first: 'First hash',
          second: 'Second hash'
        }
      },
      :number_hash => {
        :format => {
          :delimiter => ',',
          :precision => 3,
          :significant => false
        }
      }
    )
  end

  def teardown
    I18n.backend = nil
  end

  test "still returns an existing translation as usual" do
    assert_equal 'foo', I18n.t(:foo)
  end

  test "still fails for a missing key" do
    assert_equal 'translation missing: en.missing_key', I18n.t(:'missing_key')
  end

  test "does a lookup on an embedded key" do
    assert_equal 'bar foo', I18n.t(:'bar.baz')
    assert_equal 'hoo bar foo', I18n.t(:'bar.boo.baz')
  end

  test "stores a compiled lookup" do
    original_lookup = I18n::Backend::Simple.instance_method(:lookup).bind(I18n.backend)

    result = I18n.t(:'bar.baz')
    precompiled_result = original_lookup.call(:en, :'bar.baz')
    assert_equal result, precompiled_result
  end

  test "should also resolve hash lookups" do
    assert_equal I18n.t(:'bar.boo').to_s, '{:baz=>"hoo bar foo"}'
  end

  test 'handles non-string results from lookup' do
    assert_equal '{:delimiter=>",", :precision=>3, :significant=>false}', I18n.t(:'number_hash.format', :locale => :en, :default => {}).to_s
  end

  test "stores a compiled hash lookup" do
    original_lookup = I18n::Backend::Simple.instance_method(:lookup).bind(I18n.backend)

    result = I18n.t(:'bar.boo')
    precompiled_result = original_lookup.call(:en, :'bar.boo')
    assert_equal result, precompiled_result
  end

  test "correctly returns a hash" do
    result = I18n.t(:'hash_lookup')

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

  test "correctly translates a hash reference with count" do
    assert_equal 'hashes', I18n.t(:'hash_lookup', count: 5)
  end

  test "correctly translates a hash reference when called directly" do
    assert_equal 'hashes', I18n.t(:'hash_lookup.other')
  end

  test "correctly translates a hash reference when called directly even when nested" do
    assert_equal 'Second hash', I18n.t(:'hash_lookup.deeper.second')
  end

  test "correctly fails for a hash reference that is not present" do
    assert_equal 'translation missing: en.hash_lookup.deeper.not_there.really',
                 I18n.t(:'hash_lookup.deeper.not_there.really')
  end
end
