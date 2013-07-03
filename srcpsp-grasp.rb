# encoding: utf-8

$:.unshift File.dirname(__FILE__)

require "srcpsp-grasp/project"
require "srcpsp-grasp/solution"
require "srcpsp-grasp/solver"

module SRCPSP_GRASP
  
  # Shortcut to read project from a file and solve it.
  def self.solve(file, options={})
    Solver.new(options).solve(Project.from_file(file))
  end
  
end
