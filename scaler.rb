require 'bundler/setup'
Bundler.require

require './lib/heroku_wrapper'
require './lib/sidekiq_wrapper'
require './lib/new_relic_wrapper'

module Scaler
  extend self

  def stats_workers
    heroku = HerokuWrapper.new('sv-stats', range: 1..12)
    sidekiq = SidekiqWrapper.new('stats', queues: %w[stats stats-slow])
    historic = sidekiq.historic(5)
    p "Stats historic: #{historic}"
    if historic.sum == 0
      heroku.ps_decrement(:worker)
    elsif historic.sum > 2000 && historic[-1] > historic[-2]
      heroku.ps_increment(:worker)
    end
  end

  def my_workers
    heroku = HerokuWrapper.new('sv-my', range: 1..3)
    sidekiq = SidekiqWrapper.new('stats', queues: %w[my my-high my-loader my-low my-mailer])
    heroku.ps_scale(:worker, sidekiq.size > 100 ? 3 : 1)
  end

  def data_webs
    new_relic = NewRelicWrapper.new(1898958) # data2.sv.app
    heroku = HerokuWrapper.new('sv-data2', range: 2..5)
    p "Data rpm: #{new_relic.throughput}"
    heroku.ps_scale(:web, (new_relic.throughput / 2000.0).ceil)
  end

  def scout_workers
    heroku = HerokuWrapper.new('sv-scout')
    sidekiq = SidekiqWrapper.new('scout', queues: %w[scout])
    heroku.ps_scale(:worker, sidekiq.size > 1 ? 1 : 0)
  end
end

module Clockwork
  every(30.seconds, 'Stats workers') { Scaler.stats_workers }
  every(15.seconds, 'My workers') { Scaler.my_workers }
  every(30.seconds, 'Data webs') { Scaler.data_webs }
  every(30.seconds, 'Scout workers') { Scaler.scout_workers }
end
