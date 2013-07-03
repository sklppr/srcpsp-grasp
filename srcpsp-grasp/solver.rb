module SRCPSP_GRASP
  
  class Solver

    # Initialize with a project and options.
    def initialize(project, options={})
      @project = project
      @n_solutions = options[:n_solutions] || 50
      @p_lft = options[:p_lft] || 0
      @p_random = options[:p_random] || 0
      @p_inverse = options[:p_inverse] || 0
      @min_iterations = options[:min_iterations] || 1
      @max_iterations = options[:max_iterations] || (@project.activities.size/10).to_i
    end
  
    # Finds a maximally good solution for the given project and options3.
    def find_solution
      
      # Start with an empty solution set.
      @solutions = []

      # Generate first batch of solutions with special p_lft and p_random.
      p_lft, p_random = @p_lft, @p_random
      @p_lft, @p_random = 0.95, 0.05
      @n_solutions.times { @solutions << generate_solution }
      @p_lft, @p_random = p_lft, p_random

      # Generate new solutions until satisfied.
      100.times do
        
        # Generate new solution.
        solution = generate_solution
        
        # Evaluate the solution to estimate its makespan.
        solution.evaluate!

        # Add solution if better than worst in current set.
        add_solution_if_improved(solution)

      end
      
      # Return best solution.
      best_solution

    end
  
    # Generate random solution.
    def generate_solution
  
      # Create new solution and pass reference to project.
      solution = Solution.new(@project)
  
      # Number of iterations to keep the same reference for.
      iterations = 0
  
      # Repeat for activity count.
      @project.activities.size.times do
  
        # Determine activities with all predecessors already in solution.
        eligible_activities = @project.activities.select do |a|
          a.predecessors.all? { |p| solution.activities.include?(p) }
        end
  
        # Count down the number of iterations.
        if iterations > 0
          iterations -= 1
        else
          # Select a new reference.
          reference = random_reference
          # Randomly pick a new iteration count.
          iterations = [@min_iterations, @min_iterations].sample
        end
  
        # Select activity according to reference.
        activity = case reference
          # Activity with latest finish time.
          when :lft then eligible_activities.sort_by(&:lft).last
          # Random activity from eligible set.
          when :random then eligible_activities.sample
          # Next best activity according to the reference.
          else reference.activities.first { |a| eligible_activities.include?(a) }
        end
  
        # Add activity to solution.
        solution << activity

      end
  
    end
  
    # Randomly selects a reference, either a Solution or :lft or :random.
    def random_reference
      case Random.rand
        when 0..@p_lft then :lft
        when 0..(@p_lft + @p_random) then :random
        when 0..(@p_lft + @p_random + @p_inverse) then @solutions.sample.invert
        else @solutions.sample
      end
    end

    # Adds solution to the set if it's better than the currently worst solution.
    def add_solution_if_improved(solution)
      
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