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
  
end
