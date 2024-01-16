require 'active_support'
require 'active_support/core_ext'

module I18n
  module Backend
    module RecursiveLookup

      # ${} for embedding, $${} for escaping
      TOKENIZER                    = /(\$\$\{[^\}]+\}|\$\{[^\}]+\})/
      INTERPOLATION_SYNTAX_PATTERN = /(\$)?(\$\{([^\}]+)\})/

      protected

      def lookup(locale, key, scope = [], options = {})
        result = super

        unless result
          normalized_key = I18n.normalize_keys(nil, key, scope)
          return if normalized_key.size < 2

          # simply strip the last key part, e.g.
          # `foo.bar.baz` becomes `foo.bar`
          normalized_key.slice!(-1, 1)

          # look the stripped key up - if this is a reference, it will
          # get compiled and cached
          lookup(locale, normalized_key, [], options)

          # then try again to get our result - it will be found now if the
          # previous `lookup` call compiled a new reference with our key,
          # otherwise still stay nil
          result = super
        end

        return result unless (result.is_a?(String) or result.is_a?(Hash))

        compiled_result, had_to_compile_result = deep_compile(locale, result, options)

        if had_to_compile_result
          cache_compiled_result(locale, key, compiled_result, scope, options)
        end

        compiled_result
      end

      #subject is hash or string
      def deep_compile(locale, subject, options)
        if subject.is_a?(Hash)
          subject = subject.deep_dup if subject.frozen?
          subject.each do |key, object|
            subject[key], _had_to_compile_result = deep_compile(locale, object, options)
          end
        else
          compile(locale, subject, options)
        end
      end

      def compile(locale, string, options)
        had_to_compile_result = false

        if string.is_a?(String)
          result = string.split(TOKENIZER).map do |token|
            embedded_token = token.match(INTERPOLATION_SYNTAX_PATTERN)

            if embedded_token
              had_to_compile_result = true
              handle_interpolation_match(locale, embedded_token, options)
            else
              token
            end
          end

          result = (
            result.second && (
              result.second.is_a?(Array) || result.second.is_a?(Hash)
            )
          ) ? result.second : result.join
        else
          result = string
        end

        [result, had_to_compile_result]
      end

      def cache_compiled_result(locale, dot_form_key, compiled_result, scope, options)
        keys = I18n.normalize_keys(locale, dot_form_key, scope, options[:separator])

        translation_hash = {}
        # ignore prepended locale key
        keys[1..-1].inject(translation_hash) do |hash, key|
          key == keys[-1] ? hash[key] = compiled_result : hash[key] = {}
        end

        store_translations(locale, translation_hash, options)
      end

      def handle_interpolation_match(locale, embedded_token, options)
        escaped, pattern, key = embedded_token.values_at(1, 2, 3)
        escaped ? pattern : I18n.translate(key, locale: locale)
      end
    end
  end
end
