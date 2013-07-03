module SRCPSP_GRASP
  
  # An activity has an ID, a duration, resource usage and successors.
  # `resource_usage` will be an array with resource IDs as indices and usages as values.
  # `predecessors` and `successors` will be arrays with activity IDs.
  Activity = Struct.new :id, :duration, :resource_usage, :predecessors, :successors
  
  # A resource has an ID and a capacity.
  Resource = Struct.new :id, :capacity
  
  # A project encapsulates activities and resources.
  class Project
    
    attr_accessor :activities, :resources
    
    # Initialize.
    def initialize
      @activities = []
      @resources = []
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

        # Map successors to predecessors.
        project.activities.each do |activity|
          activity.successors.each do |successor_id|
            project.activities[successor_id].predecessors << activity.id
          end
        end
        
        # Return project.
        project
        
      end
      
    end
    
  end

end
