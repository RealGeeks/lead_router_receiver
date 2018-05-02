module LeadRouterReceiver
  class Engine < ::Rails::Engine
    isolate_namespace LeadRouterReceiver
    config.generators.api_only = true

    config.generators do |g|
      g.test_framework :rspec
    end
  end
end
