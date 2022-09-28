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
  post 'order/recap', to: 'orders#recap', as: 'order_recap'

  get '/retur/:id/picked', to: 'returs#picked', as: 'retur_picked'
  get '/retur/:id/feedback', to: 'retur_items#feedback', as: 'retur_feedback'
  post 'retur/:id/confirm_feedback', to: 'retur_items#feedback_confirmation', as: 'retur_feedback_confirmation'

  delete '/sign_out', to: 'sessions#destroy'

  get '/api/:api_type', to: 'apis#index'

  get '/trx/post', to: 'transactions#create_trx'

  get '/get/:store_id', to: 'gets#index'
  post '/api/post/:type', to: 'posts#index'
  get '/refresh/balance', to: 'balances#refresh'
  get '/transaction/daily/recap', to: 'transactions#daily_recap', as: "daily_trx_recap"
  get '/transaction/daily/recap_item', to: 'transactions#daily_recap_item', as: "daily_trx_item_recap"
  get '/transaction/monthly/recap', to: 'transactions#monthly_recap', as: "monthly_trx_recap"
  
  get '/download/:type', to: 'downloads#serve_file', as: "download"
  get '/file/download', to: 'downloads#get_file', as: "download_file"

  get '/set/exchange_points', to: 'exchange_points#set_on_off', as: 'set_exchange_point'
  
  get '/absent/daily/recap', to: 'absents#daily_recap', as: "daily_absent_recap"
  
  get '/user/absent/:id', to: 'absents#user_recap', as: "user_absent_recap"
  get '/user/receivable/:id', to: 'receivables#user_recap', as: "user_receivable_recap"
  
  get '/bs/receive', to: 'send_backs#receive', as: 'send_back_receive'
  post '/bs/receive', to: 'send_backs#received', as: 'send_back_received'


  post '/opname_day', to: 'warning_items#opname_day', as: 'opname_day'
  get '/opname', to: 'warning_items#opname', as: 'opname_form'
  post '/opname', to: 'warning_items#update_stock', as: 'opname'

  post '/item_recaps', to: 'items#item_recaps', as: 'item_recaps'
  post '/supplier_item_recaps', to: 'supplier_items#item_recaps', as: 'supplier_item_recaps'
  post '/supplier_order_recaps', to: 'suppliers#recap_order', as: 'supplier_order_recaps'
  post '/tax_recap', to: 'taxs#recap', as: 'tax_recap'
  
  get '/clean/prints', to: 'prints#clean', as: "clean_prints"
  get '/print/salary', to: 'salaries#print_salary', as:"print_salary"
  get '/popular/items/refresh', to: 'homes#popular_items', as: 'refresh_popular_items'
  get '/popular/items/departments', to: 'departments#popular_items', as: 'departments_popular_items'
  get '/refresh/predict/item/:id', to: 'items#refresh_predict', as: 'refresh_predict_item'
  get '/predict/item/:id', to: 'items#predict', as: 'predict_item'

  get '/recap/item/:id', to: 'items#recap_item', as: 'recap_item'

  get '/salary/:id/delete', to: 'salaries#delete_salary', as: 'delete_salary'

  get '/print/suppliers', to: 'suppliers#print_debt_receive', as: 'print_debt_receive'

  get '/backup/download/:id', to: 'backups#download', as: 'backup_download'
  
  get '/sync/:id/:target', to: 'apis#get_sync', as: 'get_sync'
  post '/reset/user/:id', to: 'users#reset_password', as: "reset_password"


  resources :discounts
  resources :pays, only: %i[new create]
  resources :populars
  resources :opnames
  resources :balances
  resources :promotions
  resources :prints
  resources :loss_profits
  resources :stock_recaps

  resources :send_backs
  
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

  resources :members

  resources :returs
  resources :retur_items

  resources :complains, only: %i[index new create show]

  resources :absents, only: %i[index show]

  resources :transfers
  
  resources :losses
  resources :loss_items

  resources :warning_items

  resources :orders
  resources :order_items

  resources :transactions, only: %i[index new create show]

  resources :cash_flows, only: %i[index new create]
  resources :debts
  resources :receivables
  resources :taxs, only: %i[index new create]
  resources :fix_costs, only: %i[index new create]
  resources :operationals, only: %i[index new create]
  resources :stock_values, only: %i[index new create]
  # resources :assets, only: %i[index new create]


  resources :controllers
  resources :methods

  resources :activities, only: %i[index show]

  resources :server_informations, only: %i[index]

  resources :backups

  resources :kasbons

  
  get "/403", to: "errors#no_access_right", as: 'no_access_right'
  get "/404", to: "errors#not_found", as: 'not_found'
  get "/422", to: "errors#unacceptable", as: 'unacceptable'
  get "/500", to: "errors#internal_error", as: 'internal_error'

end
