# encoding: utf-8

module SRCPSP_GRASP
  
  class Solution
  
    attr_accessor :activities
    
    # Initialize with a project.
    def initialize(project, options)
      # Store options to pass on to cloned solutions.
      @options = options
      # Reference to original project.
      @project = project
      # Activity list.
      @activities = []
      # Number of replications for calculating the expected makespan.
      @n_replications = options[:n_replications] || 10
      # Probability distribution to use for calculating the expected makespan.
      @distribution = options[:distribution] || :none
    end
  
    # Shortcut to add an activity.
    def <<(activity)
      @activities << activity
    end

    # Shortcut to test if activity is included.
    def include?(activity)
      @activities.include?(activity)
    end
  
    # Returns solution with inverted activity list.
    def invert
      solution = Solution.new(@project, @options)
      solution.activities = @activities.reverse
      solution
    end

    # Calculates expected makespan.
    def expected_makespan
      @expected_makespan ||= estimate_makespan(@n_replications)
    end

    # Calculates true makespan (within 1%).
    def true_makespan
      @true_makespan ||= estimate_makespan(1000)
    end

    # Estimates makespan by generating given number of schedules from the activity list (serial SGS).
    def estimate_makespan(replications)
      # Collect makespans for given number of replications.
      makespans = []
      replications.times do
        # Draw activity durations from given distribution.
        activity_durations = @activities.collect { |activity| Distribution.send(@distribution, activity.duration) }
        # Calculate makespan for these activity durations.
        makespans << calculate_makespan(activity_durations)
      end
      # Set expected makespan to be the average of collected makespans.
      makespans.inject(:+) / makespans.size
    end

    # Calculates makespan for given activity durations by generating a schedule from activity list (serial SGS).
    def calculate_makespan(activity_durations)
      # Keep track of scheduled activities.
      scheduled_activities = []
      # The generated schedule will contain start times with activity IDs as indices.
      schedule = []
      # Iterate through remaining activities, including dummy sink.
      @activities.each do |activity|
        # Determine earliest start of activity:
        # 1. ES >= latest finish of all predecessors. (default rule of serial SGS)
        # 2. ES must be >= latest start of all scheduled activities. (activitiy-based priority rule)
        # 3. If activity has no predecessors, its earliest start is 0.
        # 4. If schedule is empty, the latest start in the schedule is 0.
        finish_times = activity.predecessors.collect { |predecessor| schedule[predecessor.id] + activity_durations[predecessor.id] }
        time = [(finish_times.max || 0), (schedule.reject(&:nil?).max || 0)].max
        # Next, determine point in time where the activity is resource feasible.
        # The way this solution was generated already ensures time feasibility.
        # Start by testing wether it's already feasible. Otherwise ...
        unless activity_is_resource_feasible?(activity, activity_durations, schedule, scheduled_activities, time)
          # Collect finish times of ongoing activities, sorted ascending.
          finish_times = scheduled_activities.select do |activity|
            schedule[activity.id] <= time && time < schedule[activity.id] + activity_durations[activity.id]
          end.collect do |activity|
            schedule[activity.id] + activity_durations[activity.id]
          end.sort
          # Test feasibility at each finish time.
          finish_times.each do |finish_time|
            time = finish_time and break if activity_is_resource_feasible?(activity, activity_durations, schedule, scheduled_activities, time)
          end
        end
        # Schedule activity at the resulting point in time.
        schedule[activity.id] = time
        scheduled_activities << activity
      end
      # Return resulting makespan.
      schedule[@activities.last.id]
    end

    # Tests if an activity is resource feasible at a certain point in time.
    def activity_is_resource_feasible?(activity, activity_durations, schedule, scheduled_activities, time)
      # Determine ongoing activities and add potential activity.
      activities = scheduled_activities.select do |activity|
        schedule[activity.id] <= time && time < schedule[activity.id] + activity_durations[activity.id]
      end << activity
      # Return wether capacity of each resource is >= sum of resource usage by all activities.
      @project.resources.all? do |resource|
        resource.capacity >= activities.inject(0) { |sum, activity| sum + activity.resource_usage[resource.id] }
      end
    end
  
  end
  
end
