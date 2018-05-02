Rails.application.routes.draw do
  mount LeadRouterReceiver::Engine => "/lead_router_receiver"
end
