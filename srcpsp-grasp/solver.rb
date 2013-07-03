# encoding: utf-8

module SRCPSP_GRASP
  
  class Solver

    # Initialize with a project and options.
    def initialize(options={})
      @n_solutions = options[:n_solutions] || 50
      @p_lft = options[:p_lft] || 0
      @p_random = options[:p_random] || 0
      @p_inverse = options[:p_inverse] || 0
      @min_iterations = options[:min_iterations] || 1
      @max_iterations = options[:max_iterations] || 10
    end
  
    # Finds a maximally good solution for the given project.
    def solve(project)
      
      # Store project.
      @project = project

      # Start with an empty solution set.
      @solutions = []

      # Generate first batch of solutions with special p_lft and p_random.
      p_lft, p_random = @p_lft, @p_random
      @p_lft, @p_random = 0.95, 0.05
      @n_solutions.times { add_solution generate_solution }
      @p_lft, @p_random = p_lft, p_random

      # Generate new solutions until satisfied.
      100.times do
        
        # Generate new solution.
        solution = generate_solution

        # Add solution if better than worst in current set.
        add_solution_if_improvement(solution)

      end
      
      # Return best solution.
      best_solution

    end
  
    # Generate random solution.
    def generate_solution
  
      # Create new solution and pass reference to project.
      solution = Solution.new(@project)
      solution << @project.activities.first
  
      # Reference and number of iterations to keep the same reference for.
      reference = nil
      iterations = 0

      # Repeat for activity count.
      @project.size.times do
  
        # Determine activities with all predecessors already in solution.
        eligible_activities = @project.activities.select do |activity|
          activity.predecessors.all? { |predecessor| solution.include?(predecessor) }
        end
  
        # Count down the number of iterations.
        if iterations > 0
          iterations -= 1
        else
          # Select a new reference.
          reference = random_reference
          # Randomly pick a new iteration count.
          iterations = [@min_iterations, @max_iterations].sample
        end

        # Select activity according to reference.
        activity = case reference
          # Activity with latest finish time.
          when :lft then eligible_activities.sort_by(&:latest_finish_time).last
          # Random activity from eligible set.
          when :random then eligible_activities.sample
          # Next best activity according to the reference.
          else reference.activities.first { |a| eligible_activities.include?(a) }
        end
  
        # Add activity to solution.
        solution << activity

      end

      # Return solution.
      solution
  
    end
  
    # Randomly selects a reference, either a Solution or :lft or :random.
    def random_reference
      # Draw a random number and compare it to probabilities.
      case Random.rand
        when 0..@p_lft then :lft # Indicate that activity with latest finish time should be chosen.
        when 0..(@p_lft + @p_random) then :random # Indicate that a random activity should be chosen.
        when 0..(@p_lft + @p_random + @p_inverse) then @solutions.sample.invert # Return inverted sample.
        else @solutions.sample # Return random sample from solution set.
      end
    end

    # Adds solution and calculates its makespan if necessary.
    def add_solution(solution)

      # If necessary, calculate the solution's makespan.
      solution.calculate_makespan! unless solution.makespan

      # Add solution to solution set.
      @solutions << solution

    end

    # Adds solution to the set if it's better than the currently worst solution.
    def add_solution_if_improvement(solution)
      
      # If necessary, calculate the solution's makespan.
      solution.calculate_makespan! unless solution.makespan

      # Sort existing solutions by makespan.
      @solutions.sort_by!(&:makespan)

      # Add it to the set if it's better than the currently worst solution.
      if solution.makespan < @solutions.last.makespan
        @solutions.delete @solutions.last
        @solutions << solution
      end

    end
  
    # Returns solution with minimal makespan.
    def best_solution

      # Sort existing solutions by makespan.
      @solutions.sort_by!(&:makespan)

      # First solution is the best one.
      @solutions.first

    end
  
  end
  
end
