# encoding: utf-8

require "csv"
require "./srcpsp-grasp"

partitions = [ (0...120), (120...240), (240...360), (360...480) ]

partition = ARGV[0].to_i
distribution = ARGV[1].to_sym
inverse = ARGV[2] == "inverse"

options = {
  distribution: distribution,
  p_random: inverse ? 0 : 0.05,
  p_inverse: inverse ? 0.05 : 0,
  max_solutions: 500,
  max_unsuccessful_solutions: 100,
}

output = "data/j30rcp-#{distribution}#{"-inverse" if inverse}-#{partition}.csv"
files = Dir["data/j30rcp/*.RCP"][partitions[partition-1]]

CSV.open(output, "wb") do |csv|
  csv << %w[ instance makespan ]
end

solver = SRCPSP_GRASP::Solver.new(options)
files.each do |file|
  project = SRCPSP_GRASP::Project.from_file(file)
  solution = solver.solve(project)
  CSV.open(output, "ab") do |csv|
    csv << [ File.basename(file, ".RCP"), solution.expected_makespan ]
  end
end
