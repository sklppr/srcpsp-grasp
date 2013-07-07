# encoding: utf-8

module SRCPSP_GRASP
  
  class Solver

    # Initializes solver with a project and options.
    def initialize(options={})
      # Store options to pass them on to solutions.
      @options = options
      # Number of solutions to keep in the solution set.
      @solution_set_size = options[:solution_set_size] || 10
      # Maximum number of solutions to generate, including initial batch.
      @max_solutions = options[:max_solutions] || 100
      # Maximum number of solutions to generate without improvement, not used by default.
      @max_unsuccessful_solutions = options[:max_unsuccessful_solutions] || @max_solutions
      # Probability of choosing activity by latest finish time.
      @p_lft = options[:p_lft] || 0
      # Probability of choosing activity randomly.
      @p_random = options[:p_random] || 0
      # Probability of inverting the reference solution.
      @p_inverse = options[:p_inverse] || 0
      # Minimum number of iterations to keep a reference for.
      @min_reference_iterations = options[:min_reference_iterations] || 1
      # Maximum number of iterations to keep a reference for.
      @max_reference_iterations = options[:max_reference_iterations] || 10
    end
  
    # Finds a maximally good solution for the given project.
    def solve(project)
      # Store project.
      @project = project
      # Let the project calculate earliest/latest start/finish times.
      @project.calculate_start_and_finish_times!
      # Start with an empty solution set.
      @solutions = []
      # Generate first batch of solutions with special p_lft and p_random.
      p_lft, p_random = @p_lft, @p_random
      @p_lft, @p_random = 0.95, 0.05
      @solution_set_size.times { @solutions << generate_solution }
      @p_lft, @p_random = p_lft, p_random
      # Initialize solution counters, include solution set size in total solution count.
      n_solutions = @solution_set_size
      n_unsuccessful_solutions = 0
      # Generate solutions until the limit of either total or unsuccessful solutions is reached.
      until n_unsuccessful_solutions == @max_unsuccessful_solutions || n_solutions == @max_solutions
        # Generate a new solution and add it if better than worst in current set.
        # Reset or increment unsuccessful solutions counter accordingly
        if add_solution_if_improvement(generate_solution)
          n_unsuccessful_solutions = 0
        else
          n_unsuccessful_solutions += 1
        end
        # Increment total solution counter.
        n_solutions += 1
      end
      # Return best solution.
      best_solution
    end
  
    # Generate random solution.
    def generate_solution
      # Create new solution and pass project and options.
      solution = Solution.new(@project, @options)
      # Reference and number of iterations to keep the same reference for.
      reference = nil
      iterations = 0
      # Repeat for activity count.
      @project.activities.size.times do
        # Determine activities that are not yet part of the solution with all predecessors already in solution.
        eligible_activities = (@project.activities - solution.activities).select do |activity|
          activity.predecessors.all? { |predecessor| solution.include?(predecessor) }
        end
        # Count down the number of iterations.
        if iterations > 0
          iterations -= 1
        else
          # Select a new reference.
          reference = random_reference
          # Randomly pick a new iteration count.
          iterations = [@min_reference_iterations, @max_reference_iterations].sample
        end
        # Select activity according to reference.
        activity = case reference
          # Activity with smallest latest finish time.
          when :lft then eligible_activities.sort_by(&:latest_finish).first
          # Random activity from eligible set.
          when :random then eligible_activities.sample
          # Next best activity according to the reference.
          else reference.activities.find { |a| eligible_activities.include?(a) }
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

    # Adds solution to the set if it's better than the currently worst solution.
    # Return wether the solution was added or now.
    def add_solution_if_improvement(solution)
      # Sort existing solutions by expected makespan.
      @solutions.sort_by!(&:expected_makespan)
      # Add it to the set if it's better than the currently worst solution.
      if solution.expected_makespan < @solutions.last.expected_makespan
        @solutions.delete @solutions.last
        @solutions << solution
        true
      else
        false
      end
    end
  
    # Returns solution with minimal expected makespan.
    def best_solution
      # Sort existing solutions by expected makespan.
      @solutions.sort_by!(&:expected_makespan)
      # First solution is the best one.
      @solutions.first
    end
  
  end
  
end
