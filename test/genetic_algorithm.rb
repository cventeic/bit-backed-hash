# Author::    Sergio Fierens
# License::   MPL 1.1
# Project::   ai4r
# Url::       http://ai4r.org/
#
# You can redistribute it and/or modify it under the terms of 
# the Mozilla Public License version 1.1  as published by the 
# Mozilla Foundation at http://www.mozilla.org/MPL/MPL-1.1.txt

module Enumerable

    def sum
      self.inject(0){|accum, i| accum + i }
    end

    def mean
      self.sum/self.length.to_f
    end

    def median
      self.sort!
      index = (self.size / 2.0).round
      self[index]
    end

    def sample_variance
      m = self.mean
      sum = self.inject(0){|accum, i| accum +(i-m)**2 }
      sum/(self.length - 1).to_f
    end

    def standard_deviation
      return Math.sqrt(self.sample_variance)
    end

end 

module Ai4r

  # The GeneticAlgorithm module implements the GeneticSearch and Chromosome 
  # classes. The GeneticSearch is a generic class, and can be used to solved 
  # any kind of problems. The GeneticSearch class performs a stochastic search 
  # of the solution of a given problem.
  # 
  # The Chromosome is "problem specific". Ai4r built-in Chromosome class was 
  # designed to model the Travelling salesman problem. If you want to solve other 
  # type of problem, you will have to modify the Chromosome class, by overwriting 
  # its fitness, reproduce, and mutate functions, to model your specific problem.
  module GeneticAlgorithm

    #   This class is used to automatically:
    #   
    #     1. Choose initial population
    #     2. Evaluate the fitness of each individual in the population
    #     3. Repeat
    #           1. Select best-ranking individuals to reproduce
    #           2. Breed new generation through crossover and mutation (genetic operations) and give birth to offspring
    #           3. Evaluate the individual fitnesses of the offspring
    #           4. Replace worst ranked part of population with offspring
    #     4. Until termination
    #
    #   If you want to customize the algorithm, you must modify any of the following classes:
    #     - Chromosome
    #     - Population
    class GeneticSearch

      attr_accessor :population

      def initialize(initial_population_size, generations)
        @population_size = initial_population_size
        @max_generation = generations
        @generation = 0
        @prand = Random.new
        @breed_count = ((2*@population_size)/3).round
      end

      #     1. Choose initial population
      #     2. Evaluate the fitness of each individual in the population
      #     3. Repeat
      #           1. Select best-ranking individuals to reproduce
      #           2. Breed new generation through crossover and mutation (genetic operations) and give birth to offspring
      #           3. Evaluate the individual fitnesses of the offspring
      #           4. Replace worst ranked part of population with offspring
      #     4. Until termination    
      #     5. Return the best chromosome
      def run
        generate_initial_population()                    #Generate initial population 

        (1..@max_generation).each do |generation_number|
          puts "\nGeneration #{generation_number}"

          fitness_range = get_fitness_range(@population)

          next if fitness_range.max == fitness_range.min

          @population.sort!()

          selected_to_breed = selection()              # Evaluates current population 

          offsprings = reproduction(selected_to_breed) # Generate the population for this new generation

          replace_worst_ranked(offsprings)

          puts to_s()

          mutate()

          increment_age()
        end

        #return best_chromosome()
        return @population.sort { |a, b| b.fitness <=> a.fitness}
      end


      def generate_initial_population
        @population = @population_size.times.map { Chromosome.seed() }
      end

      def get_fitness_range(population)
        return Range.new(0.0, 0.0) unless population.size > 0

        population.sort!()

        best_fitness  = population.first.fitness
        worst_fitness = population.last.fitness
        Range.new(worst_fitness, best_fitness)
      end

      # Select best-ranking individuals to reproduce
      # 
      # Selection is the stage of a genetic algorithm in which individual 
      # genomes are chosen from a population for later breeding. 
      # There are several generic selection algorithms, such as 
      # tournament selection and roulette wheel selection. We implemented the
      # latest.
      # 
      # Steps:
      # 
      # 1. The fitness function is evaluated for each individual, providing fitness values
      # 2. The population is sorted by descending fitness values.
      # 3. The fitness values ar then normalized. (Highest fitness gets 1, lowest fitness gets 0). The normalized value is stored in the "normalized_fitness" attribute of the chromosomes.
      # 4. A random number R is chosen. R is between 0 and the accumulated normalized value (all the normalized fitness values added togheter).
      # 5. The selected individual is the first one whose accumulated normalized value (its is normalized value plus the normalized values of the chromosomes prior it) greater than R.
      # 6. We repeat steps 4 and 5, 2/3 times the population size.    
      def selection()
        acum_fitness = 0

        fitness_range = get_fitness_range(@population)

        if fitness_range.max - fitness_range.min > 0
          @population.each do |chromosome| 
            acum_fitness += chromosome.get_normalized_fitness(fitness_range)
          end
        end

        # selected_to_breed
        @breed_count.times.map { select_random_individual(acum_fitness, fitness_range) }
      end

      # We combine each pair of selected chromosome using the method 
      # Chromosome.reproduce
      #
      # The reproduction will also call the Chromosome.mutate method with 
      # each member of the population. You should implement Chromosome.mutate
      # to only change (mutate) randomly. E.g. You could effectivly change the
      # chromosome only if 
      #     rand < ((1 - chromosome.normalized_fitness) * 0.4)
      def reproduction(selected_to_breed)
        0.upto(selected_to_breed.length/2-1).map do |i|
          offspring = Chromosome.reproduce(selected_to_breed[2*i], selected_to_breed[2*i+1])
          offspring.age = -1
          offspring 
        end
      end

      def mutate()
        # Only mutate parents
        parents = @population.to_a.select { |p| (p.age()>=0) }

        parent_fitness_range = get_fitness_range(parents)

        parents.each do |individual|
          Chromosome.mutate(individual, parent_fitness_range)
        end
      end

      def increment_age()
        @population.each do |individual|
          individual.age += 1
        end
      end

      # Replace worst ranked part of population with offspring
      def replace_worst_ranked(offsprings)
        size = offsprings.length

        @population.sort!() # Make sure population is sorted so we replace the worst 

        raise "@population.first.fitness() >= @population.last.fitness()" unless @population.first.fitness() >= @population.last.fitness()

        @population = @population [0..((-1*size)-1)] + offsprings
      end

      # Select the best chromosome in the population
      def best_chromosome()
        the_best = @population[0]
        @population.each do |chromosome|
          the_best = chromosome if chromosome.fitness > the_best.fitness
        end
        return the_best
      end

      def to_s() 
        @population.sort!() # sort by fitness

        puts "\nPopulation:"

        @population.each_with_index {|p,i| 
          puts "population[#{i}]  = #{p.to_s}"
        }

        puts "best, median, worst  = #{
          [@population.first.fitness, @population.median.fitness, @population.last.fitness].join(", ")}"

        ages = @population.map { |individual| individual.age() }
        puts "individual.ages = #{ages.join(',')}"

        aged_count = 0
        @population.each {|individual| aged_count += 1 if individual.age() >= 0}
        puts "#{((aged_count.to_f/@population.size)*100.0).round}% are parents"
      end

      private 
      def select_random_individual(acum_fitness, fitness_range)
        select_random_target = acum_fitness * @prand.rand(0.0...1.0) # not inclusive of 1.0
        # puts "select_random_target = #{select_random_target}, acum_fitness = #{acum_fitness}"

        local_acum = 0.0
        @population.each_with_index do |chromosome, index|
          nf = chromosome.get_normalized_fitness(fitness_range)
          local_acum += nf 
          #puts "in loop, index = #{index}, nf = #{nf}, local_acum = #{local_acum}"
          return chromosome if local_acum >= select_random_target
        end
      end

    end

    # A Chromosome is a representation of an individual solution for a specific 
    # problem. You will have to redifine the Chromosome representation for each
    # particular problem, along with its fitness, mutate, reproduce, and seed 
    # methods.
    class Chromosome
      include Comparable

      attr_accessor :data, :age

      def initialize(data)
        @data = Marshal.load(Marshal.dump(data))
        @age  = 0
      end

      def ==(another) 
        self.data() == another.data()
      end

      def <=>(another)
        another.fitness() <=> self.fitness()
      end

      def get_normalized_fitness(fitness_range)
        raise "fitness_range.min > fitness_range.max, fitness_range = #{fitness_range}" if fitness_range.min.nil?

        if (fitness_range.max - fitness_range.min) > 0
          f = (fitness().to_f - fitness_range.min)/(fitness_range.max - fitness_range.min).to_f
        else
          puts "warning: converged: fitness_range.delta = 0.0: fitnes_range = #{fitness_range}"
          f = 1.0
        end
        f
      end

      # The fitness method quantifies the optimality of a solution 
      # (that is, a chromosome) in a genetic algorithm so that that particular 
      # chromosome may be ranked against all the other chromosomes. 
      # 
      # Optimal chromosomes, or at least chromosomes which are more optimal, 
      # are allowed to breed and mix their datasets by any of several techniques, 
      # producing a new generation that will (hopefully) be even better.
      def fitness()
        return @fitness if @fitness

        raise "inside fitness even though defined and not nill" if @fitness

        last_token = @data[0]
        cost = 0

        @data[1..-1].each do |token|
          cost += @@costs[last_token][token]
          last_token = token
        end

        @fitness = -1 * cost

        return @fitness.to_f
      end

      # mutation method is used to maintain genetic diversity from one 
      # generation of a population of chromosomes to the next. It is analogous 
      # to biological mutation. 
      # 
      # The purpose of mutation in GAs is to allow the 
      # algorithm to avoid local minima by preventing the population of 
      # chromosomes from becoming too similar to each other, thus slowing or even 
      # stopping evolution.
      # 
      # Calling the mutate function will "probably" slightly change a chromosome
      # randomly. 
      #
      # This implementation of "mutation" will (probably) reverse the 
      # order of 2 consecutive random nodes 
      # (e.g. from [ 0, 1, 2, 4] to [0, 2, 1, 4]) if:
      #     ((1 - chromosome.normalized_fitness) * 0.4)
      def self.mutate(chromosome, fitness_range)

        normalized_fitness = chromosome.get_normalized_fitness(fitness_range)

        percent_from_best = 1.0 - normalized_fitness
        probability_of_mutation = percent_from_best * 0.3

        # best  chromosome has  0% probability of mutation
        # worst chromosome has 30% probability of mutation

        if normalized_fitness && @@prand.rand(0.0...1.0) < probability_of_mutation
          data = chromosome.data
          # switch two bits
          index = @@prand.rand(data.length-1)
          data[index], data[index+1] = data[index+1], data[index]
          chromosome.data = data
          @fitness = nil
        end
      end

      # Reproduction method is used to combine two chromosomes (solutions) into 
      #   a single new chromosome. 
      # There are several ways to combine two chromosomes: 
      #   One-point crossover, 
      #   Two-point crossover,
      #   "Cut and splice", 
      #   edge recombination,
      #   and more. 
      # The method is usually dependant of the problem domain.
      #
      def self.reproduce(a, b)
        self.reproduce_one_point_crossover(a, b)
      end

      # Reproduce with One-point crossover, 
      #
      def self.reproduce_one_point_crossover(a, b)
        # Determine which parent is left and right side randomly 
        a, b = b, a if @@prand.rand(0.0..1.0) < 0.5  # Was 0.5 ???

        # Create spawn bitmap by joining a split point in parent bit space
        last_bit     = (a.data.size) - 1 
        split_index  = @@prand.rand(last_bit)
        child_bitmap = a.data[0..split_index] + b.data[(split_index+1)..last_bit]

        return Chromosome.new(child_bitmap)
      end

      # Reproduce with edge recombination
      #   which is the most used reproduction algorithm for the Travelling salesman problem.
      def self.reproduce_edge_recombination(a, b)
        data_size = @@costs[0].length

        # available = [0,1,2,3,..,n-1]
        available = 0.upto(data_size-1).map { |n| n }
        
        token = a.data[0]
        spawn = [token]

        available.delete(token) # remove token from array available

        while available.length > 0 do 
          # Select next

          b_index_of_token = b.data.index(token) # index of first instance of token in b array
          b_next_token     = b.data[b_index_of_token + 1]

          a_index_of_token = a.data.index(token) # index of first instance of token in a array
          a_next_token     = a.data[a_index_of_token + 1]

          if token != b.data.last && available.include?(b_next_token)
            next_token = b_next_token
          elsif token != a.data.last && available.include?(a_next_token)
            next_token = a_next_token
          else
            next_token = available[@@prand.rand(available.length)]
          end

          #Add to spawn
          token = next_token
          available.delete(token) # remove token from array available
          spawn << next_token

          a, b = b, a if @@prand.rand(0.0..1.0) < 0.4  # Why 0.4 ???
        end

        return Chromosome.new(spawn)
      end

      # Initializes an individual solution (chromosome) for the initial 
      # population. Usually the chromosome is generated randomly, but you can 
      # use some problem domain knowledge, to generate a 
      # (probably) better initial solution.
      def self.seed
        data_size = @@costs[0].length

        available = []
        0.upto(data_size-1) { |n| available << n }

        seed = []
        while available.length > 0 do 
          index = @@prand.rand(available.length)
          seed << available.delete_at(index)
        end
        
        return Chromosome.new(seed)
      end

      def self.set_cost_matrix(costs)
        @@costs = costs
        @@prand = Random.new
      end

      def to_s
        out = []
        out << [:fitness, fitness().round(2)]
        out << [:age, age]
        out << [:data, data.to_s]
        out.join(", ")
      end
    end
  end
end
