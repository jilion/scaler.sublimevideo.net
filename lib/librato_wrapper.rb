require 'singleton'

class LibratoWrapper
  include Singleton

  def initialize
    Librato::Metrics.authenticate ENV['LIBRATO_USER'], ENV['LIBRATO_TOKEN']
    @queue = Librato::Metrics::Queue.new
  end

  def add(*args)
    @queue.add *args
  end

  def submit
    @queue.submit
  end
end
