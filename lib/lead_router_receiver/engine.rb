module LeadRouterReceiver
  class Engine < ::Rails::Engine
    isolate_namespace LeadRouterReceiver
    config.generators.api_only = true

    config.generators do |g|
      g.test_framework :rspec
    end

    config.to_prepare do
      Dir.glob( Rails.root + "app/decorators/**/*_decorator*.rb" ).each do |c|
        require_dependency(c)
      end
    end
  end
end
