# config/initializers/cors.rb

    Rails.application.config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins '*' # Allows all origins
        resource '*', # Allows all resources (paths)
          headers: :any, # Allows all headers
          methods: [:get, :post, :put, :patch, :delete, :options, :head] # Allows all common HTTP methods
      end
    end