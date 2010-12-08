#ActionController::Routing::Routes.draw do
  match 'forms/:id/:action/:field_id', :controller => "forms"
  match 'forms/:id/:action', :controller => "forms"
  
  resources :forms
#end