Rails.application.routes.draw do
  devise_for :users
  root to: "espacos#index"

  resources :espacos do
    member do
      post :arquivar
      post :restaurar
    end
    resources :membros, controller: "membros_espaco", only: %i[create update destroy]
    resources :investidores, except: %i[index show destroy] do
      member do
        post :arquivar
        post :restaurar
      end
      resources :carteiras, except: %i[index destroy] do
        member do
          post :arquivar
          post :restaurar
        end
        resources :contas, controller: "contas_investimento", path: :contas_investimento, except: %i[index show destroy] do
          member do
            post :arquivar
            post :restaurar
          end
          resources :caixas, controller: "contas_caixa", only: :create do
            member do
              post :arquivar
              post :restaurar
            end
          end
        end
      end
    end
    resources :transacoes, controller: "transacoes_financeiras" do
      collection { post :prever }
      member do
        post :confirmar
        post :reverter
        post :corrigir
        get :correcao
      end
    end
  end

  namespace :admin do
    resources :ativos, :instituicoes, :moedas, :fontes_cotacao, except: :destroy do
      member do
        post :arquivar
        post :restaurar
      end
    end
    resources :cotacoes_ativos, only: %i[index new create update] do
      member { post :liberar_automacao }
    end
    resources :cotacoes_cambio, only: %i[index new create update]
  end
end
