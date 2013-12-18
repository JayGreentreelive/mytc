class Node
  include Mongoid::Document
  include RandomId
  include Sluggable
  include Visible
end
