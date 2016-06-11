Rails.application.routes.draw do

  # Root
  root :to => "pages#home"

  get "/route" => "pages#stops"
  get "/predictions" => "pages#predictions"
  
end
