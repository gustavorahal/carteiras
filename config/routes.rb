Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  root to: 'application#index'

  resources :ativos do
    resources :cotacoes
  end

  get '/cotacoes', to: 'cotacoes#index_all'

  resources :corretoras
  resources :investidores

  resources :carteiras do
    resources :operacoes
    get 'ganho_de_capital', to: 'impostos#ganho_de_capital'
    get 'posicao_ano_anterior', to: 'impostos#posicao_ano_anterior'
    get 'movimentacoes', to: 'movimentacoes#index'
    get 'proventos', to: 'proventos#index'
    get 'rentabilidade', to: 'rentabilidade#index'
    resources :conta_correntes do
      resources :extratos do
        collection { post 'import' }
      end
    end
  end

  get '/carteira_ativos/:carteira_id', to: 'carteira_ativos#index', as: 'carteira_ativos'
  get '/carteira_ativos/:carteira_id/ativos/:ativo_id', to: 'carteira_ativos#show', as: 'carteira_ativo'

  resources :referencias do
    resources :referencia_ativos
  end

end