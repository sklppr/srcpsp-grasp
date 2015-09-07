# Analyzer & Solver for Project Scheduling Problems

This is a tool to analyze stochastic resource-constrained project scheduling problems (SRCPSPs) and solve them using a greedy randomized adaptive search procedure (GRASP).

Example usage:

```ruby
# Analyze problem and inspect metrics.
metrics = SRCPSP_GRASP.analyze(file)
puts metrics[:network_complexity]
puts metrics[:critical_path_length]
puts metrics[:resource_strength]

# Solve problem and inspect solution.
solution = SRCPSP_GRASP.solve(file)
puts solution.activities
puts solution.expected_makespan
puts solution.true_makespan
```

`SRCPSP_GRASP.analyze` and `SRCPSP_GRASP.solve` are shortcuts to load a project from a file, instantiate an analyzer or solver and then use it to analyze or solve the problem. The following sections describe how these steps work in detail.

## Loading a problem

Project definitions for scheduling problems can be read from RCP files available from [PSPLIB](http://www.om-db.wi.tum.de/psplib/main.html):

```ruby
project = SRCPSP_GRASP::Project.from_file("example.rcp")
```

A project can have **activities** and **resources**.

Activities have an ID, a duration, resource usages, predecessors and successors as well as earliest and latest start and finish times.

Resources will have an ID and a capacity.

Right after loading the project, earliest/latest start/finish times for activities can be calculated using the Triple algorithm:

```ruby
project.calculate_start_and_finish_times!
```

*Note: This doesn't have to be done when using the analyzer or solver, but it can be useful in isolation.*

## Analyzing a problem

The analyzer extracts several metrics to describe scheduling problems. This can also be useful when trying compare the performance of solvers with different configurations.

The following metrics can be extracted:
- **Network complexity** (ratio of adjacencies to network size) – `:network_complexity`
- **Order strength** (ratio of adjacencies to number of possible adjacencies) – `:order_strength`
- **Critical path length** (sequence of activities adding up to the longest overall duration) – `:critical_path_length`
- **Resource factor** (average portion of resources requested per activity) – `:resource_factor`
- **Resource strength** (difference between buffer and variance in resource usage) – `:resource_strength`
- **Resource constrainedness** (ratio of average demand to availability) – `:resource_constrainedness`

*Note: The project's transitive adjacency matrix will automatically be calculated using the Triple algorithm.*

To analyze a problem, simply create an analyzer for the project and call `analyze`. This will return a hash of metric names and their values.

```ruby
analyzer = SRCPSP_GRASP::Analyzer.new(project)
metrics = analyzer.analyze
```

*Note: Initializing an analyzer will automatically calculate earliest/latest start/finish times for the project.*

By default, all available metrics are extracted. You can also select which metrics to extract by passing an array of symbols to `analyze`:

```ruby
metrics = analyzer.analyze([:network_complexity, :critical_path_length])
```

## Solving a problem

The solver uses a metaheuristic to find a solution of acceptable quality in acceptable time. To quote [Wikipedia](https://en.wikipedia.org/wiki/Greedy_randomized_adaptive_search_procedure):

> GRASP typically consists of iterations made up from successive constructions of a greedy randomized solution and subsequent iterative improvements of it through a local search.

A problem is solved by iteratively generating solutions and selecting the best one:

- Start with empty solution set.
- Until maximum number of solutions is reached:
  - Generate a solution.
  - If solution is better than the currently worst one:
    - Remove currently word solution from solution set.
    - Add new solution to solution set.
- Return best solution in solution set.

A solution is found by generating a randomized but valid order of activities:

- Until all activities have been scheduled:
  - Determine activities that can be scheduled using adjacencies.
  - Choose activity to be scheduled using a reference activity:
    - With probability *pRandom* choose a random activity.
    - With probability *pLFT* choose activity with smallest latest finish time.
    - Otherwise choose a random solution from solution set to pick an activity from it:
      - With probability *pInverse* invert order of solution.
      - Choose first activity from solution that can currently be scheduled.
  - Keep reference activity for a random number of iterations, then determine a new one.

To solve a problem, simply instantiate a solver and call `solve` which returns the best found solution:

```ruby
solver = SRCPSP_GRASP::Solver.new(options)
solution = solver.solve(project)
```

The following options can be set when initializing a solver:

- **Solution set size** (number of solutions to keep in the solution set, default: 10) – `:solution_set_size`
- **Max. solutions** (maximum number of solutions to generate, including initial batch, default: 100) – `:max_solutions`
- **Max. unsuccessful solutions** (maximum number of solutions to generate without improvement, not used by default) – `:max_unsuccessful_solutions`
- **pLFT** (probability of choosing activity by latest finish time, default: 0) – `:p_lft`
- **pRandom** (probability of choosing activity randomly, default: 0) – `:p_random`
- **pInverse** (probability of inverting the reference solution, default: 0) – `:p_inverse`
- **Min. reference iterations** (minimum number of iterations to keep a reference for, default: 1) – `:min_reference_iterations`
- **Max. reference iterations** (maximum number of iterations to keep a reference for, default: 10) – `:max_reference_iterations`
- **Distribution** (distribution to use when randomly selecting activities, default is none) – `:distribution`
  - **No distribution** (input value) – `:none`
  - **Uniform distribution** (random value from uniform distribution) – `:uniform`
  - **Uniform squared** (random value from uniform distribution with interval `[d-sqrt(d), d+sqrt(d)]`) – `:uniform_sqrt`
  - **Uniform 2** (random value from uniform distribution with interval `[0, 2*d]`) – `:uniform_2`

A solution contains the IDs of activities in order (`solution.activities`) as well as the expected makespan (`solution.expected_makespan`) and true makespan within 1 % of the actual value (`solution.true_makespan`).

## Concurrency

If you have multiple CPU cores available, you might want to solve multiple problems in parallel or run multiple solvers on the same problem to compare performance. To do this, `SRCPSP_GRASP::Concurrency` offers two convenience methods to do stuff in either threads or processes (2 are used by default), depending on your Ruby runtime.

Examples:

```ruby
# Solve multiple problems using the same solver in 2 threads.
SRCPSP_GRASP::Concurrency.in_threads do |number|
  solver.solve(projects[number])
end
```

```ruby
# Run multiple solvers on the same problem in 4 processes.
SRCPSP_GRASP::Concurrency.in_processes(4) do |number|
  solvers[number].solve(project)
end
```
