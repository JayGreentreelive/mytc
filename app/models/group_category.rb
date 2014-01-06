class GroupCategory
  include Mongoid::Document
  include RandomId
  include Nillable
  include Treeable
  
  DEFAULT_NAME = 'New Category'
  
  field :name, type: String, default: -> { self.class::DEFAULT_NAME }

  
  normalize_attribute :name, with: [:blank, :squish]
  #normalize_attribute :system, with: :true_or_nil
  
  embedded_in :group
  
  def nodes(page: 1, page_size: 10, deep: false)
    
    if deep == true
      cats = self.descendants_and_self.map(&:id)
    else
      cats = [self.id]
    end
    
    node_ids = Node.collection.aggregate({ '$match' => { 'postings' => { '$elemMatch' => { 'target_id' => self.group.id, 'category_id' => { '$in' => cats }}} }}, { '$unwind' => '$postings' }, { '$project' => { '_id' => 1 }}, { '$limit' => page_size }, { '$skip' => ((page - 1) * page_size) }).map { |c| c['_id'] }
    all_nodes = Node.find(nodes_ids).index_by { |p| p.id }
    node_ids.map { |p| all_nodes[p] }
  end
  
  def remove_self(orphans = parent)
    puts "Removing self... orphans -> #{orphans.to_s}"
  end

end
