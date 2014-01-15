class Node
  include Mongoid::Document
  include RandomId
  include Sluggable
  include Visible
  include Flaggable
  
  #embeds_many :postings
  
  
  
end
