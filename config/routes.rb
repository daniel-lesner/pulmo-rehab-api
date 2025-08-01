Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"

  api_version(module: "V1", path: { value: "api/v1" }) do
    jsonapi_resources :sessions, only: [ :create ]
    jsonapi_resources :users, only: [ :create, :show, :index, :update, :destroy ]
    jsonapi_resources :doctors, only: [ :create, :show ]
    jsonapi_resources :bracelets, only: [ :create, :show, :index, :destroy ]
    jsonapi_resources :dashboards, only: [ :create ]
    jsonapi_resources :air_pollutions, only: [ :create ]
    jsonapi_resources :health_data, only: [ :create, :show, :index, :update, :destroy ]

    post "webhooks/garmin", to: "webhooks#garmin"
  end
end
