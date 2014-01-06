class Node
  include Mongoid::Document
  include RandomId
  include Sluggable
  include Visible
  
  embeds_many :postings
  
  
end
