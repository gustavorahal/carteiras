Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  root to: 'application#index'

  resources :ativos do
    resources :cotacoes
  end
  resources :corretoras
  resources :conta_correntes do
    resources :extratos do
      collection { post 'import' }
    end
  end
  resources :investidores

  resources :carteiras do
    resources :operacoes
    get 'impostos', to: 'impostos#index'
  end

  get '/carteira_ativos/:carteira_id', to: 'carteira_ativos#index', as: 'carteira_ativos'
  get '/carteira_ativos/:carteira_id/ativos/:ativo_id', to: 'carteira_ativos#show', as: 'carteira_ativo'

  resources :referencias do
    resources :referencia_ativos
  end

end