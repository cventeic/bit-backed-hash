require 'minitest/autorun'

module Bit_Backed_Hash
  class Range_Map 
    def initialize(range_a, range_b)
      @range_a = range_a
      @range_b = range_b

      @range_a_span = range_a.max - range_a.min

      @range_b_span = range_b.max - range_b.min
    end

    def map_to_a(value_in_b)
      percent_of_range = (value_in_b - @range_b.min).to_f / @range_b_span
      value_in_a       = (@range_a_span * percent_of_range) + @range_a.min 
      value_in_a
    end

    def map_to_b(value_in_a)
      percent_of_range = (value_in_a - @range_a.min).to_f / @range_a_span
      value_in_b       = (@range_b_span * percent_of_range) + @range_b.min 
      value_in_b
    end
  end
end

class Test_Range_Map < MiniTest::Unit::TestCase
  include Bit_Backed_Hash

  def test_range_map_int_to_float
    rm = Range_Map.new((0..10), (0..100))

    [0, 5, 7.5, 10].each do |a_value|
      b_value = rm.map_to_b(a_value)
      assert_equal a_value, b_value / 10
    end

    [0, 50, 75, 100].each do |b_value|
      a_value = rm.map_to_a(b_value)
      assert_equal b_value, a_value * 10
    end
  end

  def test_range_map_float_to_float
    rm = Range_Map.new((0.0..1.0), (0.0..10.0))

    [0.0, 0.5, 1.0].each do |a_value|
      b_value = rm.map_to_b(a_value)
      assert_equal a_value, b_value / 10.0
    end

    [0.0, 5.0, 10.0].each do |b_value|
      a_value = rm.map_to_a(b_value)
      assert_equal b_value, a_value * 10.0
    end
  end
end

