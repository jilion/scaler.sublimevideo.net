class SidekiqWrapper
  attr_accessor :app, :queues

  def initialize(app, queues: [])
    @app = app
    @queues = queues
  end

  def size
    queues.map { |queue| Sidekiq::Queue.new(queue).size }.sum
  end

  def historic(n)
    Sidekiq.redis { |con|
      con.ltrim(_redis_key, 0, n - 1)
      con.rpush(_redis_key, size)
      con.lpop(_redis_key) if con.llen(_redis_key) > n
      con.lrange(_redis_key, 0, n - 1)
    }.map(&:to_i)
  end

  private

  def _redis_key
    "scaler-#{app}"
  end

end
