# encoding: utf-8

module SRCPSP_GRASP

  # `resource_usage` will be an array with resource IDs as indices and usages as values.
  # `predecessors` and `successors` will be arrays with activity IDs.
  Activity = Struct.new :id, :duration, :resource_usage, :predecessors, :successors,
    :earliest_start, :latest_start, :earliest_finish, :latest_finish
  
  Resource = Struct.new :id, :capacity
  
  class Project
    
    attr_accessor :activities, :resources
    
    # Initialize.
    def initialize
      @activities = []
      @resources = []
    end

    # Shortcut to retrieve project size.
    def size
      @activities.size
    end
    
    # Calculates earliest/latest start/finish times using the Triple algorithm.
    def calculate_start_and_finish_times!

      # Initialize distance matrix with negative infinity and 0 in the diagonal.
      n = @activities.size
      distance = Array.new(n) { |i| Array.new(n) { |j| i == j ? 0 : -Float::INFINITY } }
      
      # For all precedences (i,j) set the distance to the duration of i.
      @activities.each do |activity|
        activity.successors.each do |successor|
          distance[activity.id][successor.id] = activity.duration
        end
      end
      
      # For all activities (use IDs):
      activities = @activities.collect(&:id)
      activities.each do |a|

        # For all pairs (i,j) not including a ...
        ij = activities - [a]
        ij.each do |i|
          # ... and a cost d[i,a] > negative infinity:
          next if distance[i][a] == -Float::INFINITY

          # If the path i->a->j is longer than i->j until now, set i->a->j as new distance between i and j.
          ij.each { |j| distance[i][j] = [ distance[i][j], distance[i][a] + distance[a][j] ].max }

        end
      end
      
      # Set earliest/latest start/finish times of each activity.
      @activities.each do |a|
        a.earliest_start = distance[0][a.id]
        a.latest_start = -distance[a.id][0]
        a.earliest_finish = a.earliest_start + a.duration
        a.latest_finish = a.latest_start + a.duration
      end

    end

    # Reads project from a PSPLIB file (.RCP).
    def self.from_file(file)
      
      # Create project.
      project = Project.new
      
      # Read file.
      File.open(file, "r") do |file|
        
        # First line contains number of activities and resources.
        line = file.gets.split
        n_activities = line[0].to_i
        n_resources = line[1].to_i
        
        # Second line contains resource availability.
        line = file.gets.split
        n_resources.times do |k|
          project.resources << Resource.new(k, line[k].to_i)
        end
        
        # The next remaining lines contain activities.
        n_activities.times do |i|
          
          # Format: duration [usage]{n_resources} n_successors [successor]{n_successors}
          line = file.gets.split
          duration = line[0].to_i
          resource_usage = line[1..n_resources].map { |r| r.to_i }
          n_successors = line[n_resources + 1].to_i
          # Fix successor IDs by subtracting 1 so that they correspond to array indices.
          successors = line[(n_resources+2)..(n_resources+1+n_successors)].map { |j| j.to_i - 1 }
          
          # Add new activity to project, leave predecessors empty for now.
          project.activities << Activity.new(i, duration, resource_usage, [], successors)
        
        end

        # Replace successor indices with references.
        project.activities.each do |activity|
          activity.successors = activity.successors.map { |successor_id| project.activities[successor_id] }
        end

        # Add activities as predecessor to their successors.
        project.activities.each do |activity|
          activity.successors.each { |successor| project.activities[successor.id].predecessors << activity }
        end

        # Return project.
        project
        
      end
      
    end
    
  end

end
