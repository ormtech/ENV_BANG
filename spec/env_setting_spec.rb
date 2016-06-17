require_relative 'spec_helper'

RSpec.describe EnvSetting do

  it "Raises exception if unconfigured ENV var requested" do
    ENV['UNCONFIGURED'] = 'unconfigured'
    expect { described_class.unconfigured }.to raise_error NoMethodError
    expect { described_class['UNCONFIGURED'] }.to raise_error KeyError
  end

  it "Raises exception if configured ENV var is not present" do
    ENV.delete('NOT_PRESENT')

    expect {
      described_class.config do
        use 'NOT_PRESENT'
      end
    }.to raise_error KeyError
  end

  it "Should define two methods for each configured ENV var" do
    ENV['CUSTOM_VAR'] = 'foo'

    described_class.config do
      use 'CUSTOM_VAR'
    end

    expect(described_class).to respond_to(:custom_var)
    expect(described_class).to respond_to(:custom_var?)
  end

  it "Uses provided default value if ENV var not already present" do
    ENV.delete('WASNT_PRESENT')

    described_class.config do
      use 'WASNT_PRESENT', default: 'a default value'
    end
    expect(EnvSetting.wasnt_present).to eq 'a default value'
  end

  it "Returns actual value from ENV if present" do
    ENV['PRESENT'] = 'present in environment'

    described_class.config do
      use 'PRESENT', default: "You won't need this."
    end
    expect(EnvSetting.present).to eq 'present in environment'
  end

  describe "Type casting" do
    let(:truthy_values) { %w[true on yes yo yup anything] }
    let(:falsey_values) { %w[false no off disable disabled 0] << '' }
    let(:integers) { %w[0 1 10 -42 -55] }
    let(:floats) { %w[0.1 1.3 10 -42.3 -55] }

    it "Casts Integers" do
      integer = integers.sample
      ENV['INTEGER'] = integer
      EnvSetting.use 'INTEGER', class: Integer

      expect(EnvSetting.integer).to eq integer.to_i
    end

    it "Casts Symbols" do
      ENV['SYMBOL'] = 'symbol'
      EnvSetting.use 'SYMBOL', class: Symbol

      expect(EnvSetting.symbol).to eq :symbol
    end

    it "Casts Floats" do
      float = floats.sample
      ENV['FLOAT'] = float
      EnvSetting.use 'FLOAT', class: Float

      expect(EnvSetting.float).to eq float.to_f
      expect(EnvSetting.float).to be_a Float
    end

    it "Casts Arrays" do
      ENV['ARRAY'] = 'one,two , three, four'
      EnvSetting.use 'ARRAY', class: Array

      expect(EnvSetting.array).to match_array(%w[one two three four])
    end

    it "Casts Arrays of Integers" do
      ENV['INTEGERS'] = integers.join(',')
      EnvSetting.use 'INTEGERS', class: Array, of: Integer

      expect(EnvSetting.integers).to match_array(integers.map(&:to_i))
    end

    it "Casts Arrays of Floats" do
      ENV['FLOATS'] = floats.join(',')
      EnvSetting.use 'FLOATS', class: Array, of: Float

      expect(EnvSetting.floats).to match_array(floats.map(&:to_f))
    end

    it "regression: Casting Array always returns Array" do
      ENV['ARRAY'] = 'one,two , three, four'
      EnvSetting.use 'ARRAY', class: Array

      2.times do
        expect(EnvSetting.array).to match_array(%w[one two three four])
      end
    end

    it "Casts Hashes" do
      ENV['HASH_VAR'] = 'one: two, three: four'
      EnvSetting.use 'HASH_VAR', class: Hash

      expect(EnvSetting.hash_var).to eq({one: 'two', three: 'four'})
    end

    it 'Casts Hashes of Integers' do
      ENV['INT_HASH'] = 'one: 111, two: 222'
      EnvSetting.use 'INT_HASH', class: Hash, of: Integer

      expect(EnvSetting.int_hash).to eq({one: 111, two: 222})
    end

    it 'Casts Hashes with String keys' do
      ENV['STRKEY_HASH'] = 'one: two, three: four'
      EnvSetting.use 'STRKEY_HASH', class: Hash, keys: String

      expect(EnvSetting.strkey_hash).to eq({'one' => 'two', 'three' => 'four'})
    end

    it "Casts true" do
      ENV['TRUE'] = truthy_values.sample
      EnvSetting.use 'TRUE', class: :boolean

      expect(EnvSetting.true).to eq true
    end

    it "Casts false" do
      ENV['FALSE'] = falsey_values.sample
      EnvSetting.use 'FALSE', class: :boolean

      expect(EnvSetting.false).to eq false
    end

    it "converts falsey or empty string to false by default" do
      ENV['FALSE'] = falsey_values.sample
      EnvSetting.use 'FALSE'

      expect(EnvSetting.false).to eq false
    end

    it "leaves falsey string as string if specified" do
      ENV['FALSE'] = falsey_values.sample
      EnvSetting.use 'FALSE', class: String

      expect(EnvSetting.false).to be_a String
    end

    it "allows default class to be overridden" do
      expect(EnvSetting.default_class).to eq :StringUnlessFalsey
      orig = EnvSetting.default_class

      EnvSetting.config { default_class String }
      ENV['FALSE'] = falsey_values.sample
      EnvSetting.use 'FALSE'

      expect(EnvSetting.false).to be_a String

      EnvSetting.default_class orig
    end

    it "allows default falsey regex to be overridden" do
      expect(EnvSetting.default_falsey_regex).to eq(/^(|0|disabled?|false|no|off)$/i)
      orig = EnvSetting.default_falsey_regex

      EnvSetting.config { default_falsey_regex(/fubar/i) }

      ENV['FALSEY'] = 'fubar'
      EnvSetting.use 'FALSEY'

      expect(EnvSetting.falsey).to be_a FalseClass

      # Reset the default for rest of tests.
      EnvSetting.default_falsey_regex orig
    end

    it "allows addition of custom types" do
      require 'set'

      ENV['NUMBER_SET'] = '1,3,5,7,9'
      EnvSetting.config do
        add_class Set do |value, options|
          Set.new self.Array(value, options || {})
        end

        use :NUMBER_SET, class: Set, of: Integer
      end

      expect(EnvSetting.number_set).to eq Set.new [1, 3, 5, 7, 9]
    end
  end

  describe "Hash-like behavior" do
    it "provides configured keys" do
      ENV['VAR1'] = 'something'
      ENV['VAR2'] = 'something else'
      EnvSetting.use 'VAR1'
      EnvSetting.use 'VAR2'

      expect(EnvSetting.keys).to include(*%w[VAR1 VAR2])
    end

    it "provides configured values" do
      ENV['VAR1'] = 'something'
      ENV['VAR2'] = 'something else'
      EnvSetting.use 'VAR1'
      EnvSetting.use 'VAR2'

      expect(EnvSetting.values).to include(*%w[something something\ else])
    end
  end

  describe "Formatting" do
    it "Includes provided description in error message" do
      ENV.delete('NOT_PRESENT')

      expect {
        EnvSetting.config do
          use 'NOT_PRESENT', 'You need a NOT_PRESENT var in your ENV'
        end
      }.to raise_error(KeyError, /You need a NOT_PRESENT var in your ENV/)
    end
  end
end
