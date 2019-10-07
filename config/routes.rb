Rails.application.routes.draw do

  get 'activities/index'
	Clearance.configure do |config|
  		config.routes = false
	end
  namespace :admin do
      resources :users
      resources :stores

      root to: "users#index"
    end
  root :to => "homes#index"

  resources :registers, only: %i[new create]

  # Clearance
  resource :session, controller: 'sessions', only:  %i[create]
  get '/sign_in', to: 'sessions#new', as: 'sign_in'

  get '/retur/:id/confirmation', to: 'returs#confirmation', as: 'retur_confirmation'
  post '/retur/:id/confirmation', to: 'returs#accept', as: 'retur_accept'

  get '/transfer/:id/confirmation', to: 'transfers#confirmation', as: 'transfer_confirmation'
  post '/transfer/:id/confirmation', to: 'transfers#accept', as: 'transfer_accept'

  get 'transfer/:id/sent', to:'transfers#picked', as: 'transfer_picked'
  post 'transfer/:id/sent', to: 'transfers#sent', as: 'transfer_sent'

  get 'transfer/:id/receive', to: 'transfers#receive', as: 'transfer_receive'
  post 'transfer/:id/received', to: 'transfers#received', as: 'transfer_received'

  get 'order/:id/receive', to: 'orders#confirmation', as: 'order_confirmation'
  post 'order/:id/receive', to: 'orders#receive', as: 'order_receive'
  get 'order/:id/edit/receive', to: 'orders#edit_confirmation', as: 'edit_order_confirmation'
  put 'order/:id/edit/receive', to: 'orders#edit_receive', as: 'edit_order_receive'
  get 'order/:id/pay', to: 'orders#pay', as: 'order_pay'
  post 'order/:id/pay', to: 'orders#paid', as: 'order_paid'

  post '/retur/:id/picked', to: 'returs#picked', as: 'retur_picked'
  get '/retur/:id/feedback', to: 'retur_items#feedback', as: 'retur_feedback'
  post '/retur/:id/confirm_feedback', to: 'retur_items#feedback_confirmation', as: 'retur_feedback_confirmation'

  delete '/sign_out', to: 'sessions#destroy'

  get '/api/:api_type', to: 'apis#index'
  post '/api/trx/post', to: 'transactions#create_trx'
  get '/get/:store_id', to: 'gets#index'
  post '/api/post/:type', to: 'posts#index'
  get '/refresh/balance', to: 'balances#refresh'

  get '/download/:type', to: 'downloads#serve_file', as: "download"
  get '/file/download', to: 'downloads#get_file', as: "download_file"

  get '/set/exchange_points', to: 'exchange_points#set_on_off', as: 'set_exchange_point'
  resources :pays, only: %i[new create]

  resources :balances
  resources :promotions
  resources :prints
  get '/clean/prints', to: 'prints#clean', as: "clean_prints"
  
  resources :items
  resources :points
  resources :vouchers
  resources :exchange_points
  resources :salaries
  resources :grocer_items
  resources :item_cats
  resources :departments
  resources :notifications, only: %i[index]

  resources :stocks
  resources :users
  resources :stores

  resources :suppliers
  resources :supplier_items
  resources :item_suppliers, only: %i[index show]

  resources :members

  resources :returs
  resources :retur_items

  resources :complains, only: %i[index new create show]

  resources :absents, only: %i[index show]

  resources :transfers
  resources :transfer_items
  
  resources :losses
  resources :loss_items

  resources :warning_items

  resources :orders
  resources :order_items

  resources :transactions, only: %i[index new create]
  resources :transaction_items, only: %i[index show]

  resources :cash_flows, only: %i[index new create]
  resources :debts, only: %i[index new create show]
  resources :receivables, only: %i[index new create show]
  resources :taxs, only: %i[index new create]
  resources :fix_costs, only: %i[index new create]
  resources :operationals, only: %i[index new create]
  resources :stock_values, only: %i[index new create]
  # resources :assets, only: %i[index new create]

  resources :controllers
  resources :methods

  resources :activities, only: %i[index show]

  resources :server_informations, only: %i[index]

  
  get "/403", to: "errors#no_access_right", as: 'no_access_right'
  get "/404", to: "errors#not_found", as: 'not_found'
  get "/422", to: "errors#unacceptable", as: 'unacceptable'
  get "/500", to: "errors#internal_error", as: 'internal_error'

end
