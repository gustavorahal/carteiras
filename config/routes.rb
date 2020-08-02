Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  root to: 'application#index'

  resources :ativos
  resources :extratos
  resources :carteira_ativos
  resources :carteiras do
    resources :operacoes
  end


end
