module SRCPSP_GRASP
  
  Activity = Struct.new :duration, :resource_usage
  
  Resource = Struct.new :capacity
  
  class Project
    
    attr_accessor :size, :activities, :resources
    
    def initialize
      @activities = []
      @resources = []
    end
    
    def size
      @activities.size
    end
      
    def self.from_file(file)
      # @TODO
    end
    
  end

end
