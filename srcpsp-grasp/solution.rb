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
  
    # Generates schedule from activity list and calculates makespan.
    def evaluate!
      # @TODO
    end
  
    # Returns solution with inverted activity list.
    def invert
      solution = self.clone
      solution.activities.reverse!
      solution
    end
  
  end
  
end