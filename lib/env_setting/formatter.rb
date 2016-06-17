class EnvSetting
  module Formatter
    def self.formatted_error(var, description)
      indent 4, <<-EOS

  Missing required environment variable: #{var}#{ description and "\n" <<
  unindent(description) }
      EOS
    end

    def self.unindent(string)
      width = string.scan(/^ */).map(&:length).min
      string.gsub(/^ {#{width}}/, '')
    end

    def self.indent(width, string)
      string.gsub "\n", "\n#{' ' * width}"
    end
  end
end
