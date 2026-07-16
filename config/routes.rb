Rails.application.routes.draw do
  devise_for :users
  root to: "carteiras#index"

  resources :carteiras, only: %i[index show] do
    resources :eventos_financeiros, only: %i[index show new create destroy] do
      member do
        post :confirmar
        post :reverter
      end
    end
    resources :contas_investimento, except: :destroy
    resources :importacoes_extrato, only: %i[new create show] do
      member do
        post :processar
        post :resolver_item
      end
    end
    get :posicao_historica
    get :rentabilidade
    get :comparacao_referencia
    get :ganho_de_capital, to: "relatorios#resultados_economicos"
    get :posicao_ano_anterior, to: "relatorios#posicao_ano_anterior"
  end

  resources :ativos
  resources :referencias do
    resources :versoes_referencia, only: %i[new create show] do
      member { post :publicar }
    end
  end
  resources :cotacoes_ativos, only: %i[index new create]
  resources :cotacoes_cambio, only: %i[index new create]
end
