# Bit_Backed_Hash

Hash used to constrain parameter search spaces by constraining parameter values to small bit arrays.

For each parameter you can:
- Define the value range (ex: 0.2 <= value <= 0.8)
- Define the value resolution in terms of bits (ex. 4, 6, 8, etc.)

For the set of parameters you can:
- Generate a concatenated bit array storing the values from all parameters
- Update the parameter values by importing a bit array

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'bit_backed_hash'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install bit-backed-hash

## Usage

Example Code:

  params = BitBackedHash.new

  # Parameter a, range 0.0 to 1.0, mapped into 4 bits / 16 values
  params.add_parameter(:a, (0.0..1.0), 4)

  # Parameter b, range 0.0 to 1.0, mapped into 6 bits / 64 values
  params.add_parameter(:b, (0.0..1.0), 6)

  params[:a] = 0.5  # Set parameter a as close to 0.5 as possible with 4 bits
  params[:b] = 0.2  # Set parameter b as close to 0.2 as possible with 6 bits

  # Generate bit array as concatenation of all bits storing parameter values
  bit_array = params.export_bits()

  # Set parameter values from a concatenated bit array
  params.import_bits(bit_array)

  # 10 bits, 4 from a and 6 from b
  assert_equal 10, bit_array.size

  # Verify value for a is within the resolution of 4 bits
  assert_in_delta 0.5, params[:a], params.parameter_resolution(:a) / 2.0

  # Verify value for b is within the resolution of 6 bits
  assert_in_delta 0.2, params[:b], params.parameter_resolution(:b) / 2.0

See test directory for an example of using BitBackedHash with Ai4r gem to do a genetic algorithm search.


## Contributing

1. Fork it ( https://github.com/[my-github-username]/bit-backed-hash/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
