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
    resources :carteira_referencias
    resources :carteira_posicoes
    resources :operacoes
    get 'impostos', action: :index, controller: 'impostos'
  end


end
