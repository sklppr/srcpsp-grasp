# encoding: utf-8

$:.unshift File.dirname(__FILE__)

require "srcpsp-grasp/analyzer"
require "srcpsp-grasp/concurrency"
require "srcpsp-grasp/distribution"
require "srcpsp-grasp/project"
require "srcpsp-grasp/solution"
require "srcpsp-grasp/solver"

module SRCPSP_GRASP
  
  # Reads project from file and solves it.
  def self.solve(file, options={})
    Solver.new(options).solve(Project.from_file(file))
  end

  # Reads project from file and analyzes it.
  def self.analyze(file, metrics=Analyzer::METRICS)
    Analyzer.new(Project.from_file(file)).analyze(metrics)
  end
  
end
