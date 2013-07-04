# encoding: utf-8

module SRCPSP_GRASP

  module Distribution

    # Returns the input value.
    def self.none(d)
      d
    end

    # Uniform distribution.
    def self.uniform(l, u)
      (l + (u - l) * Random.rand).to_i
    end

    # Exponential distribution.
    def self.exponential(d)
      (-d * Math.log(Random.rand)).to_i
    end

    # Returns random variable from uniform distribution with interval [d-sqrt(d), d+sqrt(d)].
    def self.uniform_sqrt(d)
      sqrt_d = Math.sqrt(d)
      uniform(d-sqrt_d, d+sqrt_d)
    end

    # Returns random variable from uniform distribution with interval [0, 2*d].
    def self.uniform_2(d)
      uniform(0, 2*d)
    end

  end

end
