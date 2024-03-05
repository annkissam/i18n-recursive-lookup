require 'active_support'
require 'active_support/core_ext'

module I18n
  module Backend
    module RecursiveLookup

      # ${} for embedding, $${} for escaping
      TOKENIZER                    = /(\$\$\{[^\}]+\}|\$\{[^\}]+\})/
      INTERPOLATION_SYNTAX_PATTERN = /(\$)?(\$\{([^\}]+)\})/

      def enable_interpolation_cache?
        @enable_interpolation_cache
      end

      def disable_interpolation_cache
        @enable_interpolation_cache = false
      end

      protected

      def initialize
        super
        @enable_interpolation_cache = true
      end

      def lookup(locale, key, scope = [], options = {})
        result = super

        return result unless (result.is_a?(String) or result.is_a?(Hash))

        compiled_result, had_to_compile_result = deep_compile(locale, result, options)

        if enable_interpolation_cache? && had_to_compile_result
          cache_compiled_result(locale, key, compiled_result, scope, options)
        end

        compiled_result
      end

      #subject is hash or string
      def deep_compile(locale, subject, options)
        # Prevent modifying the original hash if cache is not enabled
        subject = subject&.dup unless enable_interpolation_cache?

        if subject.is_a?(Hash)
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
              handle_interpolation_match(embedded_token)
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

      def handle_interpolation_match(embedded_token)
        escaped, pattern, key = embedded_token.values_at(1, 2, 3)
        # don't call translate with the locale passed by the functions because it could be one of the fallbacks
        # it should always re-enter the lookup process with the current locale setted in I18n.locale
        escaped ? pattern : I18n.translate(key)
      end
    end
  end
end
