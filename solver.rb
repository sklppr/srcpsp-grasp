class Solver

  # Initialize with a project and options.
  def initialize(project, options)
    @project = project
    @p_lft = options[:p_lft] || 0
    @p_random = options[:p_random] || 0
    @p_inverse = options[:p_inverse] || 0
    @min_iterations = options[:min_iterations] || 1
    @max_iterations = options[:max_iterations] || (@project.size/10).to_i
  end

  # Finds best solution for project.
  def find_solution
    @solutions = []
    1000.times { generate_solution! }
    best_solution
  end
  
  # Generate random solution.
  def generate_solution!

    # Create new solution and pass reference to project.
    solution = Solution.new(@project)

    # Number of iterations to keep the same reference for.
    iterations = 0

    # Repeat for activity count.
    @project.size.times do

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
    
    # Sort existing solutions by makespan.
    @solutions.sort_by!(&:makespan)

    # Evaluate the solution to estimate its makespan.
    solution.evaluate!

    # Add it to the set if it's better than the currently worst solution.
    if solution.makespan < @solutions.last.makespan
      @solutions.delete @solutions.last
      @solutions << solution
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

  # Returns solution with minimal makespan.
  def best_solution
    @solutions.sort_by!(&:makespan)
    @solutions.first
  end

end
