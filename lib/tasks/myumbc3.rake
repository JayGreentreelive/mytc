namespace :myumbc3 do
  desc "Import myUMBC 3 data into myUMBC 4, exciting!"
  task import: :environment do
    require 'myumbc3/importer'
    Myumbc3::Importer.import
  end
  
  desc "Reset myUMBC 3 imported items"
  task reset: :environment do
    require 'myumbc3/importer'
    Myumbc3::Importer.reset
  end
  
  namespace :user do
    desc "Dump the user data into a json file"
    task :dump, [:user_id] => :environment do |t, args|
      require 'myumbc3/importer'
      Myumbc3::Importer::UserImporter.dump(args.user_id)
    end
    
    task :reset, [:user_id] => :environment do |t, args|
      require 'myumbc3/importer'
      Myumbc3::Importer::UserImporter.reset
    end
  end
  
  namespace :group do
    desc "Dump the group data into a json file"
    task :dump, [:group_id] => :environment do |t, args|
      require 'myumbc3/importer'
      Myumbc3::Importer::GroupImporter.dump(args.group_id)
    end
    
    task :reset, [:group_id] => :environment do |t, args|
      require 'myumbc3/importer'
      Myumbc3::Importer::GroupImporter.reset
    end
  end
  
  namespace :content do
    task :reset, [:group_id] => :environment do |t, args|
      require 'myumbc3/importer'
      Myumbc3::Importer::ContentImporter.reset
    end
    
    namespace :news do
      desc "Dump the group data into a json file"
      task :dump, [:news_id] => :environment do |t, args|
        require 'myumbc3/importer'
        Myumbc3::Importer::ContentImporter.news_dump(args.news_id)
      end
    end
  end
  
end
