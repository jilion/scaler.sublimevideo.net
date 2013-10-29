class NewRelicWrapper
  def initialize(app_id)
    NewRelicApi.api_key = ENV['NEW_RELIC_API_KEY']
    @app_id = app_id
  end

  def throughput
    application.threshold_values.detect { |a| a.name == 'Throughput' }.metric_value
  end

  def application
    account.applications.detect { |a| a.id = @app_id.to_s }
  end

  def account
    NewRelicApi::Account.find(:first)
  end
end
