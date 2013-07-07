# encoding: utf-8

require "csv"
require "./srcpsp-grasp"

output = "data/j30rcp-metrics.csv"
files = Dir["data/j30rcp/*.RCP"]

CSV.open(output, "wb") do |csv|
  csv << [ "instance", *SRCPSP_GRASP::Analyzer::METRICS ]
  files.each do |file|
    result = SRCPSP_GRASP.analyze(file)
    csv << [ File.basename(file, ".RCP"), *result.values ]
  end
end
