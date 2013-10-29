class HerokuWrapper
  def initialize(app, range: 0..1)
    @client = Heroku::API.new(api_key: ENV['HEROKU_API_KEY'])
    @app = app
    @range = range
  end

  def ps_n(type)
    @client.get_ps(@app).body.count {|ps| ps['process'].match /#{type}\.\d?/ }
  end

  def ps_increment(type)
    ps_scale(type, ps_n(type) + 1)
  end

  def ps_decrement(type)
    ps_scale(type, ps_n(type) - 1)
  end

  def ps_scale(type, n)
    return if n == ps_n(type)
    return unless @range.include?(n)

    @client.post_ps_scale(@app, type , n)
    puts "Scale #{@app} #{type} dynos to #{n}."
  end
end
