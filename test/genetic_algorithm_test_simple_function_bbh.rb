# Author::    Sergio Fierens
# License::   MPL 1.1
# Project::   ai4r
# Url::       http://www.ai4r.org/
#
# You can redistribute it and/or modify it under the terms of 
# the Mozilla Public License version 1.1  as published by the 
# Mozilla Foundation at http://www.mozilla.org/MPL/MPL-1.1.txt

require 'rubygems'
require 'minitest/autorun'
require 'pry'

require_relative './genetic_algorithm'
require 'bit-backed-hash'

include Bit_Backed_Hash

module Ai4r
  
  module GeneticAlgorithm

    COSTS = [[0,0,0,0,0,0,0,0,0,0]]

    class Chromosome

      def initialize(data=[])
        @hbb = BitBackedHash.new()
        @hbb.add_parameter(:x, (0.0..31.0), 8)

        @hbb.import_bits(data)

        @age  = 0
      end

      def data()
        @hbb.export_bits()
      end

      def data=(bit_array)
        @hbb.import_bits(bit_array)
      end

      # Count 1's
      def fitness()
        return @fitness if @fitness

        # puts "fitness = #{@hbb.to_s}"
        
        x = @hbb[:x]
        @fitness = (-0.1 * x**2) + (3.0 * x)

        # @fitness = 0.0 if @fitness < 0

        return @fitness
      end

      def self.reproduce(a, b)
        self.reproduce_one_point_crossover(a, b)
      end

      # Random 0's and 1's
      def self.seed
        _hbb = BitBackedHash.new()
        _hbb.add_parameter(:x, (0.0..31.0), 8)
        _hbb[:x] = @@prand.rand(0.0..31.0)  # must use range to be inclusive and decimal to be float

        bit_array = _hbb.export_bits()

        c = Chromosome.new(bit_array)
        c
        return c
      end

      def to_s
        out = []
        out << [:fitness, fitness().round(2)]
        out << [:age, age]
        out << [vars: @hbb.to_s ]
        out << [:data, data.to_s]
        out.join(", ")
      end

    end

    NULL_CHROMO_DATA = 8.times.map{0}
    COSTS = [NULL_CHROMO_DATA]

    class GeneticAlgorithmTest < MiniTest::Unit::TestCase

      def test_chromosome_seed
        Chromosome.set_cost_matrix(COSTS)
        chromosome = Chromosome.seed
        assert_equal NULL_CHROMO_DATA.size, chromosome.data.size
        #assert_equal [0, 1, 2, 3, 4, 5, 6, 7, 8, 9], chromosome.data.sort
      end

      def test_fitness
        Chromosome.set_cost_matrix(COSTS)

        hbb = BitBackedHash.new()
        hbb.add_parameter(:x, (0.0..31.0), 8)

        [0.0, 2.2, 5.0, 25.0, 31.0].each do |test_x|
          hbb[:x] = test_x

          chromosome = Chromosome.new(hbb.export_bits())
          x = hbb[:x]
          expected_fitness = (-0.1 * x**2) + (3.0 * x)

          assert_equal( expected_fitness, chromosome.fitness)
        end
       end

      def test_selection
        Chromosome.set_cost_matrix(COSTS)
        population_size =  10
        search = GeneticSearch.new(population_size, 5)
        search.generate_initial_population
        selected =  search.selection
        selected.each { |c| assert !c.nil? }

        fitness_range = search.get_fitness_range(search.population)

        assert_equal 6, selected.length

        # assert_equal 1, search.population[0].normalized_fitness
        assert_equal 1, search.population[0].get_normalized_fitness(fitness_range)

        # assert_equal 0, search.population.last.normalized_fitness
        assert_equal 0, search.population.last.get_normalized_fitness(fitness_range)
        
        assert_equal population_size, search.population.length
      end

      def test_reproduction
        Chromosome.set_cost_matrix(COSTS)
        population_size =  10
        search = GeneticSearch.new(population_size, 5)
        search.generate_initial_population
        selected =  search.selection()
        offsprings = search.reproduction(selected)
        assert_equal 3, offsprings.length
      end    

      def test_replace_worst_ranked
        Chromosome.set_cost_matrix(COSTS)
        population_size =  10
        search = GeneticSearch.new(population_size, 5)
        search.generate_initial_population
        selected =  search.selection()
        offsprings = search.reproduction(selected)
        search.replace_worst_ranked(offsprings)
        assert_equal population_size, search.population.length

        offsprings.each { |c| assert search.population.include?(c)}
      end 

      def test_configuration_bounds
        # contain the bounds of population_size and generations to get reliable
        # convergence on best solution
      end

      def test_accuracy_target
        # delta from actual best value
        # 2) test bell curve of x values
      end

      def test_fitness_targets
        repeat = 20 

        best = []
        median = []
        worst = []

        repeat.times do 
          population_size =  20
          generations     =  7 

          Chromosome.set_cost_matrix(COSTS)
          search_object = GeneticSearch.new(population_size, generations)

          final_population = search_object.run

          best   << final_population.first.fitness
          median << final_population.median.fitness
          worst  << final_population.last.fitness
        end

        puts "best   mean = #{best.mean}, stddev = #{best.standard_deviation}"
        puts "median mean = #{median.mean}, stddev = #{median.standard_deviation}"
        puts "worst  mean = #{worst.mean}, stddev = #{worst.standard_deviation}"

        assert_in_delta 22.47, best.mean, 0.05
        assert_in_delta 22.26, median.mean, 0.31
        assert_in_delta 16.00, worst.mean, 6.63 

        assert_equal true, (best.mean >= (22.47 * 0.9))
        assert_equal true, (median.mean >= (22.26 * 0.9))
        assert_equal true, (worst.mean >= (16.0 * 0.9))
      end

    end

  end

end
