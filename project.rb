Activity = Struct.new :duration, :resource_usage

Resource = Struct.new :capacity

class Project
  
  attr_accessor :size, :activities, :resources
  
  def init
    @activities = []
    @resources = []
  end
  
  def size
    @activities.size
  end
    
  def self.from_file(filename)
    # @TODO
  end

end
