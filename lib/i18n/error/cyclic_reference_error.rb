module I18n
  class CyclicReferenceError < RuntimeError
    attr_reader :keys_chain

    def initialize(keys_chain, msg = 'Cyclic Reference has been detected')
      @keys_chain = keys_chain
      super "#{msg} in chain #{@keys_chain}"
    end
  end
end
