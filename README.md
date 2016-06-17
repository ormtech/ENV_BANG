# env_setting

Inspired by [ENV!](https://rubygems.org/gems/env_bang) and [David Copeland's
article on UNIX
Environment](http://naildrivin5.com/blog/2016/06/10/dont-use-ENV-directly.html),
`env_setting` is a slight rewrite of `env_bang` to provide OOP style access to
your ENV.

<!-- [![Gem Version](https://img.shields.io/gem/v/env_bang.svg?style=flat)](https://rubygems.org/gems/env_bang) -->
<!-- [![Build Status](https://img.shields.io/travis/jcamenisch/ENV_BANG/master.svg?style=flat)](https://travis-ci.org/jcamenisch/ENV_BANG) -->
<!-- [![Dependency Status](https://img.shields.io/gemnasium/jcamenisch/ENV_BANG.svg?style=flat)](https://gemnasium.com/jcamenisch/ENV_BANG) -->
<!-- [![Code Climate](https://img.shields.io/codeclimate/github/jcamenisch/ENV_BANG.svg?style=flat)](https://codeclimate.com/github/jcamenisch/ENV_BANG) -->
<!-- [![Coverage Status](https://img.shields.io/coveralls/jcamenisch/ENV_BANG/master.svg?style=flat)](https://coveralls.io/r/jcamenisch/ENV_BANG) -->

`env_setting` is very similar to `ENV!`, it sets out to accomplish the same
purpose:

> - Provide a central place to specify all your app’s environment variables.
> - Fail loudly and helpfully if any environment variables are missing.
> - Prevent an application from starting up with missing environment variables.
>   (This is especially helpful in environments like Heroku, as your app will
>   continue running the old code until the server is configured for a new
>   revision.)

But with one extra requirement:

- Provide access to environment variables in keeping with OOP doctrine.

To accomplish that goal, Environment variables are just methods on the
`EnvSetting` class after they are configured:

```ruby
ENV["SOME_SETTING"] = "something"

EnvSetting.use "SOME_SETTING"

...

EnvSetting.some_setting
# => "something"
EnvSetting.some_setting?
# => true
```

## Installation

Add this line to your application’s Gemfile:

```ruby
gem 'env_setting'
```

Or for Rails apps, use `env_setting-rails` instead for more convenience:

```ruby
gem 'env_setting-rails'
```

And then execute:

```sh
$ bundle
```

## Usage

### Basic Configuration

Configuration style is _exactly_ the same for `env_bang` and `env_setting`, only
that there's no "ENV!" method... just the normal class: `EnvSetting` that is
called and configured.

First, configure your environment variables somewhere in your app’s startup
process. If you use the `env_setting-rails` gem, place this in `config/env.rb`
to load before application configuration.

Example configuration:

```ruby
EnvSetting.config do
  use :APP_HOST
  use :RAILS_SECRET_TOKEN
  use :STRIPE_SECRET_KEY
  use :STRIPE_PUBLISHABLE_KEY
  # ... etc.
end
```

Once a variable is specified with the `use` method, access it with

```ruby
EnvSetting.my_var
```

Or you can still use the Hash syntax if you prefer it:

```ruby
EnvSetting["MY_VAR"]
```

This will function just like accessing `ENV` directly, except that it will
require the variable to have been specified, and, if no default value is
specified, it will raise a `KeyError` with an explanation of what needs to be
configured. In the event you reference a variable that you haven't specified,
it will produce a `NoMethodError` (if using the method syntax) or a `KeyError`
if using the Hash syntax.

### Adding a default value

For some variables, you’ll want to include a default value in your code, and
allow each environment to omit the variable for default behaviors. You can
accomplish this with the `:default` option:

```ruby
EnvSetting.config do
  # ...
  use :MAIL_DELIVERY_METHOD, default: 'smtp'
  # ...
end
```

### Adding a description

When a new team member installs or deploys your project, they may run into a
missing environment variable error. Save them time by including documentation
along with the error that is raised. To accomplish this, provide a description
(of any length) to the `use` method:

```ruby
EnvSetting.config do
  use 'RAILS_SECRET_KEY_BASE',
      'Generate a fresh one with `SecureRandom.urlsafe_base64(64)`; see http://guides.rubyonrails.org/security.html#session-storage'
end
```

Now if someone installs or deploys the app without setting the
`RAILS_SECRET_KEY_BASE` variable, they will see these instructions immediately
upon running the app.

### Automatic type conversion

`env_setting` can convert your environment variables for you, keeping that
tedium out of your application code. To specify a type, use the `:class` option:

```ruby
EnvSetting.config do
  use :COPYRIGHT_YEAR,       class: Integer
  use :MEMCACHED_SERVERS,    class: Array
  use :MAIL_DELIVERY_METHOD, class: Symbol, default: :smtp
  use :DEFAULT_FRACTION,     class: Float
  use :ENABLE_SOUNDTRACK,    class: :boolean
  use :PUPPETMASTERS,        class: Hash
end
```

**Note** that arrays will be derived by splitting the value on commas (','). To
get arrays of a specific type of value, use the `:of` option:

```ruby
EnvSetting.config do
  use :YEARS_OF_INTEREST, class: Array, of: Integer
end
```

Hashes are split on commas (',') and key:value pairs are delimited by colon
(':'). To get hashes of a specific type of value, use the `:of` option, and to
use a different type for keys (default is `Symbol`), use the `:keys` option:

```ruby
EnvSetting.config do
  use :BIRTHDAYS, class: Hash, of: Integer, keys: String
end
```

#### Default type conversion behavior

If you don’t specify a `:class` option for a variable, `env_setting` defaults to
a special type conversion called `:StringUnlessFalsey`. This conversion returns
a string, unless the value is a "falsey" string `['false', 'no', 'off', '0',
'disable', 'disabled']`.  To turn off this magic for one variable, pass in
`class: String`. To disable it globally, set

```ruby
EnvSetting.config do
  default_class String
end
```

Or if you just dislike what is considered "falsey", configure your own regex
pattern of what strings are "falsey":

```ruby
EnvSetting.config do
  default_falsey_regex(/0|fubar|false|n/i)
end
```

#### Custom type conversion

Suppose your app needs a special type conversion that doesn’t come with
`env_setting`. You can implement the conversion yourself with the `add_class`
method in the `EnvSetting.config` block.  For example, to convert one of your
environment variables to type `Set`, you could write the following
configuration:

```sh
# In your environment:
export NUMBER_SET=1,3,5,7,9
```

```ruby
# In your env.rb configuration file:
require 'set'

EnvSetting.config do
  add_class Set do |value, options|
    Set.new self.Array(value, options || {})
  end

  use :NUMBER_SET, class: Set, of: Integer
end
```

```ruby
# Somewhere in your application:
EnvSetting.number_set
#=> #<Set: {1, 3, 5, 7, 9}>
```

## Implementation Notes

1. Any method that can be run within an `EnvSetting.config` block can also be run
   as a method directly on `EnvSetting`. For instance, instead of

   ```ruby
   EnvSetting.config do
      add_class Set do
        ...
      end

      use :NUMBER_SET, class: Set
   end
   ```

   It would also work to run

   ```ruby
   EnvSetting.add_class Set do
      ...
   end

   EnvSetting.use :NUMBER_SET, class: Set
   ```
   
   While the `config` block is designed to provide a cleaner configuration
   file, calling the methods directly can occasionally be handy, such as when
   trying things out in an IRB/Pry session.

## Acknowledgements

Jonathan Camenisch, the author of `ENV!`, has done substantial work of which
this gem takes advantage. This gem would not be possible without that work.
This gem simply changes the style in which the work that `ENV!` does is exposed
(i.e. via methods).

## License

This gem is licensed under the MIT License

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
