require 'bundler/setup'
Bundler.require

require './lib/heroku_wrapper'
require './lib/sidekiq_wrapper'
require './lib/new_relic_wrapper'

module Scaler
  extend self

  def stats_workers
    heroku = HerokuWrapper.new('sv-stats', range: 1..10)
    sidekiq = SidekiqWrapper.new('stats', queues: %w[stats stats-slow])
    historic = sidekiq.historic(10)

    p "Stats historic: #{historic}"

    if historic.sum == 0
      heroku.ps_decrement(:worker)
    elsif historic.sum > 2000 && historic[-1] > historic[-2]
      heroku.ps_increment(:worker)
    end
  end

  def data_webs
    new_relic = NewRelicWrapper.new(1898958) # data2.sv.app
    heroku = HerokuWrapper.new('sv-data2', range: 2..5)

    p new_relic.throughput

    heroku.ps_scale(:web, (new_relic.throughput / 2000.0).ceil)
  end
end

module Clockwork
  every(30.seconds, 'Stats workers') { Scaler.stats_workers }
  every(30.seconds, 'Data webs') { Scaler.data_webs }
end
