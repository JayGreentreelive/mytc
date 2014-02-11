Myumbc4::Application.routes.draw do

  root 'start#index'
  
  get 'login' => 'session#login', as: :login
  get 'logout' => 'session#logout', as: :logout

  get 'groups' => 'groups#index', as: :groups
  get 'groups/new' => 'groups#new', as: :new_group
  
  # Group Home
  get 'groups/:group_slug' => 'group_home#index', as: :group
  
  # Legacy Group Redirects
  get 'groups/:group_slug/news(/:id)' => 'page_not_found#legacy_group_news', as: :legacy_group_news
  # get 'groups/:group_slug/events(/:id)' => 'page_not_found#legacy_group_events', as: :legacy_group_events
  get 'groups/:group_slug/discussions(/:id)' => 'page_not_found#legacy_group_discussions', as: :legacy_group_dicussions
  get 'groups/:group_slug/media(/:id)' => 'page_not_found#legacy_group_media', as: :legacy_group_media
  get 'groups/:group_slug/spotlights(/:id)' => 'page_not_found#legacy_group_spotlights', as: :legacy_group_spotlights
  
  # Group Posts
  get 'groups/:group_slug/posts' => 'group_post#index', as: :group_posts
  get 'groups/:group_slug/posts/new' => 'group_home#index', as: :new_group_post
  get 'groups/:group_slug/posts/page/:page_number' => 'group_home#index', as: :group_posts_page
  get 'groups/:group_slug/posts/:post_id' => 'group_post#show', as: :group_post
  get 'groups/:group_slug/posts/category/:category_id' => 'group_post#index', as: :group_category
  get 'groups/:group_slug/posts/category/:category_id/page/:page_number' => 'group_home#index', as: :group_category_page
  

  # Group Events
  get 'groups/:group_slug/events' => 'group_home#index', as: :group_events
  get 'groups/:group_slug/events/new' => 'group_home#index', as: :new_group_event
  get 'groups/:group_slug/events/page/:page_number' => 'group_home#index', as: :group_events_page
  get 'groups/:group_slug/events/year/:year' => 'group_home#index', as: :group_events_year
  get 'groups/:group_slug/events/month/:year/:month' => 'group_home#index', as: :group_events_month
  get 'groups/:group_slug/events/week/:year/:week_number' => 'group_home#index', as: :group_events_week
  get 'groups/:group_slug/events/day/:year/:month/:day' => 'group_home#index', as: :group_events_day
  
  # Calendars (not yet)
  get 'groups/:group_slug/events/calendar/:calendar_id' => 'group_home#index', as: :group_event_calendar
  get 'groups/:group_slug/events/calendar/:calendar_id/page/:page_number' => 'group_home#index', as: :group_event_calendar_page

  get 'groups/:group_slug/library' => 'group_home#index', as: :group_library
  get 'groups/:group_slug/people' => 'group_home#index', as: :group_people
  get 'groups/:group_slug/settings' => 'group_home#index', as: :group_settings

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
