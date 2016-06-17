class EnvSetting
  module Classes
    class << self
      attr_writer :default_class
    end

    def self.default_class
      @@default_class ||= :StringUnlessFalsey
    end

    def self.default_falsey_regex
      @@default_falsey_regex ||= /^(|0|disabled?|false|no|off)$/i
    end

    def self.default_falsey_regex=(regex)
      @@default_falsey_regex = regex
    end

    def self.cast(value, options = {})
      public_send(:"#{options.fetch(:class, default_class)}", value, options)
    end

    def self.boolean(value, options)
      !(value =~ default_falsey_regex)
    end

    def self.Array(value, options)
      item_options = options.merge(class: options.fetch(:of, default_class))
      value.split(',').map { |v| cast(v.strip, item_options) }
    end

    def self.Hash(value, options)
      key_options   = options.merge(class: options.fetch(:keys, Symbol))
      value_options = options.merge(class: options.fetch(:of, default_class))
      {}.tap do |h|
        value.split(',').each do |pair|
          key, value = pair.split(':')
          h[cast(key.strip, key_options)] = cast(value.strip, value_options)
        end
      end
    end

    def self.Symbol(value, options)
      value.to_sym
    end

    def self.StringUnlessFalsey(value, options)
      boolean(value, options) && value
    end

    def respond_to?(method_sym)
      Kernal.respond_to?(method_sym) || super
    end

    # Delegate methods like Integer(), Float(), String(), etc. to the Kernel module
    def self.method_missing(klass, value, options = {}, &block)
      Kernel.send(klass, value)
    end
  end
end
