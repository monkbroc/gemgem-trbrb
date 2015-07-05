Rails.application.routes.draw do
  root to: 'home#index'

  resources :things do
    member do
      post :create_comment
      get :next_comments
    end
  end

  get  "sessions/sign_up_form"
  post "sessions/sign_up"
  get  "sessions/sign_out"

  get  "sessions/sign_in_form"
  post "sessions/sign_in"

  get  "sessions/activate_form/:id", controller: :sessions, action: :activate_form
  post "sessions/activate/:id", controller: :sessions, action: :activate, as: :session_activate

  resources :users
end
