# encoding: utf-8

module SRCPSP_GRASP
  
  class Analyzer

    METRICS = [ :network_complexity, :critical_path_length, :resource_factor, :resource_strength ].freeze

    # Initializes analyzer with a project.
    def initialize(project)
      @project = project
      # Let the project calculate earliest/latest start/finish times.
      @project.calculate_start_and_finish_times!
    end

    # Calculates multiple metrics and returns a hash.
    def analyze(metrics=METRICS)
      metrics.inject({}) { |result, metric| result[metric] = self.send(metric); result }
    end

    # Calculates network complexity.
    def network_complexity
      @network_complexity || = begin
        # Initialize boolean adjacency matrix.
        n = @project.activities.size
        adjacency = Array.new(n) { Array.new(n) }
        @project.activities.each { |a| a.successors.each { |s| adjacency[a.id][s.id] = true } }
        # Calculate transitive reduction using the Triple algorithm.
        n.times { |k| n.times { |i| n.times { |j| adjacency[i][j] = adjacency[i][j] && !( adjacency[i][k] && adjacency[k][j] ) } } }
        # Complexity is the ratio of adjancies (occurences of true) to network size.
        adjacency.flatten.count(true).to_f / n
      end
    end

    # Calculates critical path length.
    def critical_path_length
      @critical_path_length ||= @project.activities.last.earliest_start
    end

    # Calculates resource factor.
    def resource_factor
      @resource_factor ||= begin
        # Count how often an activity uses a resource.
        resource_usage_count = @project.activities.inject(0) do |sum, activity|
          sum += activity.resource_usage.count { |r| r > 0 }
        end
        # Resource factor is ratio of usage count to activity count to resource count.
        resource_usage_count.to_f / (@project.activities.size - 2) / @project.resources.size
      end
    end

    # Calculates resource strength.
    def resource_strength
      @resource_strength ||= begin
        # Collect strength of all resources.
        strengths = @project.resources.collect do |r|
          # Determine maximum resource usage.
          max_usage = @project.activities.collect do |i|
            # For all activities i, add up resource usage of each j (except source and sink) that will run concurrently with i.
            (@project.activities - [@project.activities.first, @project.activities.last]).inject(0) do |sum, j|
              sum + if (j.earliest_start...j.earliest_finish).include?(i.earliest_start) then j.resource_usage[r.id] else 0 end
            end
          end.max
          # Determine minimum resource usage.
          min_usage = @project.activities.collect { |a| a.resource_usage[r.id] }.max
          # Resource strength is difference between buffer and variance.
          (r.capacity - min_usage).to_f / (max_usage - min_usage)
        end
        # Return averall (= average) resource strength, exclude NaN elements.
        strengths.reject(&:nan?).inject(:+) / strengths.size
      end
    end

  end

end
