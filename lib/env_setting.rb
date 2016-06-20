require "env_setting/version"
require "env_setting/classes"
require "env_setting/formatter"

class EnvSetting
  def self.config(&block)
    class_eval(&block)
  end

  def self.use(var, *args)
    var = var.to_s
    description = args.first.is_a?(String) && args.shift
    options = args.last.is_a?(Hash) ? args.pop : {}

    unless ENV.has_key?(var)
      ENV[var] = options.fetch(:default) { raise_formatted_error(var, description) }.to_s
    end

    vars[var] = options

    method_name = var.downcase

    instance.define_singleton_method(method_name) do
      cache[method_name] ||= self.class.get_value(var)
    end

    method_name_bool = "#{method_name}?"
    instance.define_singleton_method(method_name_bool) do
      cache[method_name_bool] ||= !!(self.send(method_name))
    end
  end

  def self.raise_formatted_error(var, description)
    raise KeyError.new Formatter.formatted_error(var, description)
  end

  def self.add_class(klass, &block)
    Classes.send :define_singleton_method, klass.to_s, &block
  end

  def self.default_class(*args)
    if args.any?
      Classes.default_class = args.first
    else
      Classes.default_class
    end
  end

  def self.default_falsey_regex(regex = nil)
    if regex
      Classes.default_falsey_regex = regex
    else
      Classes.default_falsey_regex
    end
  end

  def self.respond_to?(method_sym)
    instance.respond_to?(method_sym) || super
  end

  def self.method_missing(method, *args, &block)
    instance.send(method, *args, &block)
  end

  def self.instance
    @@instance ||= new
  end

  def self.set_instance(obj)
    raise ArgumentError.new "Object must be a derivative of EnvSetting" unless obj.is_a?(EnvSetting)
    @@instance = obj
  end

  def self.vars
    @@vars ||= {}
  end

  def self.keys
    vars.keys
  end

  def self.values
    keys.map { |k| self[k] }
  end

  def self.get_value(var)
    var = var.to_s
    raise KeyError.new("#{var} is not configured in the ENV") unless vars.has_key?(var)

    Classes.cast ENV[var], vars[var]
  end

  def self.[](var)
    self.get_value(var)
  end

  def cache
    @cache ||= {}
  end

  def clear_cache!
    @cache = nil
  end

  def respond_to?(method_sym)
    ENV.respond_to?(method_sym) || super
  end

  def method_missing(method, *args, &block)
    ENV.send(method, *args, &block)
  end
end
