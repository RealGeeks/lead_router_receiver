LeadRouterReceiver::Engine.routes.draw do
  post "incoming" => "incoming#receive_message"
end
