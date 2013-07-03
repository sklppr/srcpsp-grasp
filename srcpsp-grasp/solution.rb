module SRCPSP_GRASP
  
  class Solution
  
    attr_accessor :activities, :makespan
    
    # Initialize with a project.
    def initialize(project)
      @project = project
      @activities = []
    end
  
    # Shortcut to add an activity.
    def <<(activity)
      @activities << activity
    end
  
    # Returns solution with inverted activity list.
    def invert
      solution = self.clone
      solution.activities.reverse!
      solution
    end

    # Generates schedule from activity list using a serial SGS.
    def evaluate!

      # Clone the project's resources to be able to modify their capacity.
      resources = @project.resources.clone

      # Keep track of scheduled activities.
      scheduled_activities = []

      # The generated schedule will contain start times with activity IDs as indices.
      schedule = []

      # Iterate through remaining activities, including dummy sink.
      @activities.each do |activity|

        # Determine earliest start of activity:
        # 1. ES <= latest finish of all predecessors. (default rule of serial SGS)
        time = activity.predecessors.collect do |predecessor_id|
          schedule[predecessor_id] + @project.activities[predecessor_id].duration
        end.max || 0 # If activity has no predecessors, its earliest start is 0.
        # 2. ES must be <= latest start of all scheduled activities. (activitiy-based priority rule)
        time = [time, (schedule.max || 0)].max # If schedule is empty, the latest start is 0.

        # Next, determine point in time where the activity is resource feasible.
        # The way this solution was generated already ensures time feasibility.

        # Start by testing wether it's already feasible. Otherwise ...
        unless activity_is_resource_feasible?(activity, schedule, time, scheduled_activities)

          # Collect finish times of ongoing activities, sorted ascending.
          finish_times = scheduled_activities.select do |activity|
            schedule[activity.id] <= time && time < schedule[activity.id] + activity.duration
          end.collect do |activity|
            schedule[activity.id] + activity.duration
          end.sort

          # Test feasibility at each finish time.
          finish_times.each do |finish_time|
            time = finish_time and break if activity_is_resource_feasible?(activity, schedule, time, scheduled_activities)
          end

        end

        # Schedule activity at the resulting point in time.
        schedule[activity.id] = time
        scheduled_activities << activity

      end

      # Set makespan.
      @makespan = schedule[@activities.last.id]

    end

    # Tests if an activity is resource feasible at a certain point in time.
    def activity_is_resource_feasible?(activity, schedule, time, scheduled_activities)

      # Determine ongoing activities and add potential activity.
      activities = scheduled_activities.select do |activity|
        schedule[activity.id] <= time && time < schedule[activity.id] + activity.duration
      end << activity

      # Return wether capacity of each resource is >= sum of resource usage by all activities.
      @project.resources.all? do |resource|
        resource.capacity >= activities.inject(0) { |sum, activity| sum + activity.resource_usage[resource.id] }
      end

    end
  
  end
  
end
