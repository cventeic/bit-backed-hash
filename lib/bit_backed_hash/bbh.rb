require 'minitest/autorun'
#require "bit_backed_hash/range_map"

module Bit_Backed_Hash

  def Bit_Backed_Hash.integer_to_bits(bits, value)
    #puts "integer_to_bits bits:#{bits}, value:#{value}"
    bit_array = (bits-1).downto(0).map{|n| value[n]}
    #puts "   bit_array = #{bit_array}"
    bit_array
  end

  def Bit_Backed_Hash.bits_to_integer(bit_array)
    value = bit_array.reverse.each_with_index.inject(0){|sum,pair|
      bit,index = pair
      # puts "index = #{index}, value = #{2**index}, bit = #{bit}"
      sum += (2**index) if bit == 1
      sum
    }
    value
  end

  class BitBackedHash 
    def initialize()
      @params = {}
    end

    def add_parameter(parameter_id, value_range = (0.0..1.0), value_bits = 6)

      bit_integer_range = (0..(2**value_bits-1)) 

      @params[parameter_id] = {
        value_range: value_range, 
        bits: Array.new(value_bits){0},
        range_map: Range_Map.new(value_range,bit_integer_range)
      }
    end

    def parameter_resolution(parameter_id)
      p = @params.fetch(parameter_id)

      value_bits = p[:bits].size
      bit_integers = 2**value_bits-1

      value_span       = p[:value_range].max - p[:value_range].min
      parameter_resolution = value_span/bit_integers # reserve 1 bit array combination for value_range_max

      return parameter_resolution
    end

    # Retrive parameter value
    def [](parameter_id)

      #puts "Retrieve: [#{parameter_id}]"
      #puts "  @params: #{@params.to_s}"
      p = @params.fetch(parameter_id)

      bit_integer = Bit_Backed_Hash.bits_to_integer(p[:bits])

      value = p[:range_map].map_to_a(bit_integer)

      return value
    end

    def []=(parameter_id, value)
      #puts "store: [#{parameter_id}] = #{value}"

      p = @params.fetch(parameter_id)
      #puts "p = #{p}"

      bit_integer = p[:range_map].map_to_b(value).round.to_i

      #puts "bit_integer = #{bit_integer}"
      #puts "p[:bits] = #{p[:bits]}"

      p[:bits] = Bit_Backed_Hash.integer_to_bits(p[:bits].size, bit_integer)
      #puts "    p[:bits] = #{p[:bits]}"

      # Now reverse it and return the stored value
      bit_integer = Bit_Backed_Hash.bits_to_integer(p[:bits])
      #puts "  bit_integer = #{bit_integer}"
      value = p[:range_map].map_to_a(bit_integer)

      return value  # return value???
    end

    def export_bits()
      #puts "export_bits"
      raise "no keys defined" unless @params.keys.size > 0

      bit_arrays = @params.keys.sort.map do |key|
        @params[key][:bits]
      end

      bit_arrays.flatten
    end

    def import_bits(bit_array)

      bits = bit_array.clone

      @params.keys.sort.each do |key|
        p = @params.fetch(key)

        p[:bits] = bits.shift(p[:bits].size)  # extract bits
      end
    end

  end
end


class Test_Hash_With_Bit_Backing < MiniTest::Unit::TestCase

  include Bit_Backed_Hash

  def test_a
    hash_bb = BitBackedHash.new

    hash_bb.add_parameter(:a, (0.0..1.0), 4)
    hash_bb.add_parameter(:b, (0.0..1.0), 6)

    hash_bb[:a] = 0.5
    hash_bb[:b] = 0.2

    bit_array = hash_bb.export_bits()
    hash_bb.import_bits(bit_array)

    assert_equal 10, bit_array.size

    assert_in_delta 0.5, hash_bb[:a], hash_bb.parameter_resolution(:a) / 2.0
    assert_in_delta 0.2, hash_bb[:b], hash_bb.parameter_resolution(:b) / 2.0
  end

  def test_map
    #puts "test_map:"

    h = {a: 0.0, b: 0.25, c: 0.50, d: 0.75, e: 1.0, f: 0.37}

    (4..8).each do |minimum_bits|
      #puts "  minimum_bits = #{minimum_bits}"

      hash_bb = BitBackedHash.new

      total_bits = 0
      h.each_pair {|k,v| 
        rand_part =  (rand(6) - 3).to_i

        bits_to_use = minimum_bits + rand_part
        total_bits += bits_to_use

        #puts "    bits_to_use = #{bits_to_use}"

        hash_bb.add_parameter(k, (0.0..1.0), bits_to_use)
        hash_bb[k] = v
      }

      bit_field = hash_bb.export_bits()

      #puts "  bit_field = #{bit_field.to_s}"

      assert_equal (total_bits), bit_field.size

      hash_bb.import_bits(bit_field)

      h.each_pair {|k,v| 
        #puts "  assert_in_delta #{[v, hash_bb[k], hash_bb.maps[k].value_subspan / 2.0]}"
        assert_in_delta(v, hash_bb[k], hash_bb.parameter_resolution(k) / 2.0)
      }
    end

  end
end

