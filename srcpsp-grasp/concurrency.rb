# encoding: utf-8

module SRCPSP_GRASP

  module Concurrency

    # Returns results of executing given block in given number of threads.
    def self.in_threads(n_threads=2, &block)

      # Create requested number of threads, execute block, wait and collect result.
      (0...n_threads).collect do |thread_counter|
        Thread.new { Thread.current[:result] = block.call(thread_counter) }.join[:result]
      end

    end

    # Returns results of executing given block in given number of processes.
    def self.in_processes(n_processes=2, &block)

      # Create requested number of subprocesses.
      (0...n_processes).collect do |process_counter|
        # Create two way pipe, fork.
        io_read, io_write = IO.pipe
        # Fork process.
        pid = fork do
          # In the process, close reading pipe.
          io_read.close
          # Execute block while passing process counter, marshal result to writing pipe.
          Marshal.dump(block.call(process_counter), io_write)
          # Exit process with code 0.
          exit! 0
        end
        # Outside of the process, close the writing pipe.
        io_write.close
        # Wait for the process to finish and read result from reading pipe.
        Process.wait(pid)
        Marshal.load(io_read.read)
      end

    end

  end

end