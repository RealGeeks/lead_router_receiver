module LeadRouterReceiver
  class Engine < ::Rails::Engine
    isolate_namespace LeadRouterReceiver
    config.generators.api_only = true
  end
end
