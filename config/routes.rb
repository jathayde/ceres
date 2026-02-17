Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  resources :plant_types, except: :show do
    resources :plant_categories, except: :show do
      member do
        post :research_viability
      end
      resources :plant_subcategories, except: :show
    end
  end

  resources :plants do
    member do
      post :research_growing_guide
    end
    collection do
      get :categories_for_type
      get :subcategories_for_category
    end
  end

  resources :seed_purchases, except: :show do
    member do
      patch :mark_as_used_up
      patch :mark_as_active
    end
    collection do
      patch :bulk_mark_used_up
    end
  end
  get "seed_purchases/plants_search", to: "seed_purchases#plants_search"

  resources :seed_sources, except: :show
  post "seed_sources/inline_create", to: "seed_sources#inline_create"
  get "viability_audit", to: "viability_audit#index", as: :viability_audit
  patch "viability_audit/bulk_mark_used_up", to: "viability_audit#bulk_mark_used_up", as: :viability_audit_bulk_mark_used_up
  patch "viability_audit/mark_as_used_up/:id", to: "viability_audit#mark_as_used_up", as: :viability_audit_mark_as_used_up

  resources :spreadsheet_imports, only: %i[ new create show ] do
    member do
      post :start_mapping
      get :review
      patch :update_row_mapping
      post :create_taxonomy
      get :confirm
      post :execute
    end
  end

  get "inventory/browse", to: "inventory#browse", as: :inventory_browse

  root "inventory#index"
end
