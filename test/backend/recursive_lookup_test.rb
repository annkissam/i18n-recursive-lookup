require 'test_helper'

class I18nBackendRecursiveLookupTest < Test::Unit::TestCase
  class Backend < I18n::Backend::Simple
    include I18n::Backend::RecursiveLookup
  end

  def setup
    I18n.backend = Backend.new
    I18n.backend.store_translations(:en, :foo => 'foo',
      :bar => { :baz => 'bar ${foo}' , :boo => { :baz => 'hoo ${bar.baz}'}},
      :alternate_lookup => '${baz}')
  end

  def teardown
    I18n.backend = nil
  end

  test "still returns an existing translation as usual" do
    assert_equal 'foo', I18n.t(:foo)
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

  test "stores a compiled hash lookup" do
    original_lookup = I18n::Backend::Simple.instance_method(:lookup).bind(I18n.backend)

    result = I18n.t(:'bar.boo')
    precompiled_result = original_lookup.call(:en, :'bar.boo')
    assert_equal result, precompiled_result
  end
end
