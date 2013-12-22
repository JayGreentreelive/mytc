namespace :dev do
  desc "reset the entire development environment"
  task reset: ['environment', 'db:mongoid:drop', 'db:seed'] do
    puts 'FIX: The mongoid create_indexes isn\'t working, fix it!'
    Entity.create_indexes
    puts 'Your dev environment is reset'
  end
end