# encoding: utf-8

require "csv"
require "./srcpsp-grasp"

# Select input files according to partition (with size 60).
partition = ARGV[0].to_i
files = Dir["data/j30rcp/*.RCP"]
files = files.slice((partition-1)*60, 60)

# Create solvers with different configurations.
solvers = {
  exponential: SRCPSP_GRASP::Solver.new({ distribution: :exponential, p_random: 0.05, max_solutions: 5000 }),
  exponential_inverse: SRCPSP_GRASP::Solver.new({ distribution: :exponential, p_inverse: 0.05, max_solutions: 5000 }),
  uniform: SRCPSP_GRASP::Solver.new({ distribution: :uniform_sqrt, p_random: 0.05, max_solutions: 5000 }),
  uniform_inverse: SRCPSP_GRASP::Solver.new({ distribution: :uniform_sqrt, p_inverse: 0.05, max_solutions: 5000 })
}

# Create output files and write headers.
solvers.each do |type, solver|

  CSV.open("data/j30rcp-#{type}-#{partition}.csv", "wb") do |csv|
    csv << %w[ instance expected_makespan true_makespan ]
  end

end

# Read each input file and parse project.
files.each do |file|

  project = SRCPSP_GRASP::Project.from_file(file)

  # Solve project with each solver, calculate and write makespans.
  solvers.each do |type, solver|

    solution = solver.solve(project)
    expected_makespan = solution.expected_makespan
    true_makespan = solution.true_makespan

    CSV.open("data/j30rcp-#{type}-#{partition}.csv", "ab") do |csv|
      csv << [ File.basename(file, ".RCP"), expected_makespan, true_makespan ]
    end

  end

end
