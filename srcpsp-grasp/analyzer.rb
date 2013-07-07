# encoding: utf-8

module SRCPSP_GRASP
  
  class Analyzer

    METRICS = [ :network_complexity, :order_strength, :critical_path_length, :resource_factor, :resource_strength, :resource_constrainedness ].freeze

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
        # Network complexity is the ratio of adjancies (occurences of true) to network size.
        transitive_adjacency_matrix.flatten.count(true).to_f / @project.activities.size
      end
    end

    # Calculates order strength.
    def order_strength
      @order_strength ||= begin
        # Order strength is the ratio of adjacencies (occurences of true) to number of possible adjacencies.
        n = @project.activities.size
        transitive_adjacency_matrix.flatten.count(true).to_f / (n * (n - 1) / 2)
      end
    end

    # Calculates critical path length.
    def critical_path_length
      @critical_path_length ||= @project.activities.last.earliest_start
    end

    # Calculates resource factor.
    def resource_factor
      @resource_factor ||= begin
        # Resource factor is the average portion of resources requested per activity.
        @project.activities.inject(0) do |sum, activity|
          # Count how often an activity uses a resource.
          sum += activity.resource_usage.count { |r| r > 0 }
        end.to_f  / (@project.activities.size - 2) / @project.resources.size
      end
    end

    # Calculates resource strength.
    def resource_strength
      @resource_strength ||= begin
        # Collect strength of all resources.
        strength = @project.resources.collect do |r|
          # Determine maximum resource usage.
          max_usage = @project.activities.collect do |i|
            # Add up resource usage of i and all other activities j that will run concurrently with i.
            (@project.activities - [i]).inject(i.resource_usage[r.id]) do |sum, j|
              sum + if (j.earliest_start...j.earliest_finish).include?(i.earliest_start) then j.resource_usage[r.id] else 0 end
            end
          end.max
          # Determine minimum resource usage.
          min_usage = @project.activities.collect { |a| a.resource_usage[r.id] }.max
          # Resource strength is difference between buffer and variance.
          (r.capacity - min_usage).to_f / (max_usage - min_usage)
        end
        # Return overall (= average) resource strength, exclude NaN elements.
        strength.reject(&:nan?).inject(:+) / strength.size
      end
    end

    # Calculates resource constrainedness.
    def resource_constrainedness
      @resource_constrainedness ||= begin
        # Collect constrainedness of all resources.
        constrainedness = @project.resources.collect do |r|
          # Resource constrainedness is the ratio of average demand to availability.
          @project.activities.inject(0) { |sum, a| sum + a.resource_usage[r.id] }.to_f / @project.activities.size / r.capacity
        end
        # Return overall (= average) resource constrainedness.
        constrainedness.inject(:+) / constrainedness.size
      end
    end

    # Calculates transitive adjacency matrix.
    def transitive_adjacency_matrix
      @transitive_adjacency_matrix ||= begin
        n = @project.activities.size
        # Initialize boolean adjacency matrix.
        adjacency = Array.new(n) { Array.new(n) }
        # Set given adjacencies.
        @project.activities.each { |a| a.successors.each { |s| adjacency[a.id][s.id] = true } }
        # Calculate transitive adjacencies using the Triple algorithm.
        n.times { |k| n.times { |i| n.times { |j| adjacency[i][j] = adjacency[i][j] && !( adjacency[i][k] && adjacency[k][j] ) } } }
        adjacency
      end
    end

  end

end
