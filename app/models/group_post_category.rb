#
# g.posts => GroupPostCategory
# g.posts.categories => [GroupPostCategory]
# g.posts.categories.find(id) => GroupPostCategory
# g.posts.categories.add(name: 'News', format: 'blog') => GroupPostCategory
# g.posts.categories.add(name: 'Discussions', format: 'forum')
# g.posts.categories.add(name: 'Media', format: 'gallery')
# g.posts.categories.remove(category: cat, orphans: :parent|:delete|new_cat) => GroupPostCategory

# g.posts.items(page: 1, page_size: 10, deep: true) => [Post] -- deep by default
# g.posts.items.add(item: Node, by: System, at: Time.zone.now) -> Node.add_posting(group, category, by, at)
# g.posts.items.remove(item: Node)
# GroupPostCategories move child nodes to their parent by default
# All Posts == g.posts.items(deep: true)
# Uncategorized Posts == g.posts.items(deep: false)

# g.posts.categories => [GroupPostCategory]
# g.posts.categories[1].items => [Post]
#

class GroupPostCategory < GroupCategory
  #include Orderable
  
  DEFAULT_NAME = 'New Category'
  
  FORMAT_LIST = :list
  FORMAT_BLOG = :blog
  FORMAT_FORUM = :forum
  FORMAT_GALLERY = :gallery
  
  field :format, type: Symbol, default: FORMAT_LIST

  validates :format, inclusion: { in: [FORMAT_LIST, FORMAT_BLOG, FORMAT_FORUM, FORMAT_GALLERY] }
  
  before_validation :_ensure_post_category_order
  
  def _ensure_post_category_order
    if self.root?
      unless self.group.post_category_order.all? { |a| self.categories.ids.include?(a) }
        self.group.post_category_order += (self.categories.ids - self.group.post_category_order)
      end
    end
  end
  
  # Remove a category and execute the specified dependent strategy
  #
  # @example Remove the current category, moving all dependents to this category's parent.
  #   cat.remove(dependents: :parent)
  #
  # @param [ Symbol ] dependents How to deal with any dependent categories/items. ()
  #
  # def remove(dependents: :parent)
  #   if self.root?
  #     raise "Cannot remove root category"
  #   end
  #   
  #   self.categories.each do |cat|
  #     cat.parent = self.parent
  #   end
  #   
  #   # TODO Move the items
  # end
  
  # Return an ItemsProxy containing items limited by options
  #
  def items(options = {})
    ItemCollection.new(self, options)
  end

  # Returns a CategoryCollection
  #
  def categories(options = {})
    CategoryCollection.new(self, options)
  end
  
  
  class ItemCollection
    def initialize(cat, options = {})
      
      default_options = { page_size: 10, page: 1 }
      
      @category = cat
      @find_options = default_options.merge(options)
    end
    
    def add();end
    def remove();end
    
    def inspect
      found_items.inspect
    end
    
    def ids
      found_ids
    end
    
    def stats
      
      # RAW MONGODB -- db.nodes.aggregate({ $match: { postings : { $elemMatch : { 'target_id' : 'snt4z7hkc8', 'category_id' : '2e3un4fp1o' } } } }, { $project : { _id: 1, postings: 1 } }, { $unwind : '$postings' }, { $match : { 'postings.target_id' : 'snt4z7hkc8', 'postings.category_id' : '2e3un4fp1o' } }, { $project : { _id: 1, target_id: '$postings.target_id', category_id: '$postings.category_id', at: '$postings.at' } }, { $group : { _id: { target_id: '$target_id', category_id: '$category_id' }, "count" : { $sum : 1 }, "newest" : { $max : '$at' }, "oldest" : { $min : '$at' } } } )
      
      stats = Node.collection.aggregate({
          '$match' => {
            'postings' => {
              '$elemMatch' => {
                'target_id' => @category.group.id,
                'category_id' => @category.id
              }
            }
          }
        }, {
          '$project' => {
            '_id' => 1,
            'postings' => 1
          }
        }, {
          '$unwind' => '$postings'
        }, {
          '$match' => {
            'postings.target_id' => @category.group.id,
            'postings.category_id' => @category.id
          }
        }, {
          '$project' => {
            '_id' => 1,
            'target_id' => '$postings.target_id',
            'category_id' => '$postings.category_id',
            'at' => '$postings.at'
          }
        }, {
          '$group' => {
            '_id' => {
              'target_id' => '$target_id',
              'category_id' => '$category_id'
            },
            'count' => {
              '$sum' => 1
            },
            'newest' => {
              '$max' => '$at'
            },
            'oldest' => {
              '$min' => '$at'
            }
          }
        })
        if stats.present?
          stats = { count: stats.first['count'], newest: stats.first['newest'], oldest: stats.first['oldest'] }
        else
          stats = { count: 0, newest: nil, oldest: nil }
        end
        stats
    end

    private
    
    def found_ids
      
      # RAW MONGODB -- db.nodes.aggregate({ $match: { postings : { $elemMatch : { 'target_id' : 'snt4z7hkc8', 'category_id' : '2e3un4fp1o' } } } }, { $project : { _id: 1, postings: 1 } }, { $unwind : '$postings' }, { $match : { 'postings.target_id' : 'snt4z7hkc8', 'postings.category_id' : '2e3un4fp1o' } }, { $project : { _id: 1, target_id: '$postings.target_id', category_id: '$postings.category_id', at: '$postings.at' } }, { $sort : { 'at' : -1 } }, { $skip: 0 }, { $limit: 10 } )
      
      @found_ids ||= Node.collection.aggregate({
          '$match' => {
            'postings' => {
              '$elemMatch' => {
                'target_id' => @category.group.id,
                'category_id' => @category.id
              }
            }
          }
        }, {
          '$project' => {
            '_id' => 1,
            'postings' => 1
          }
        }, {
          '$unwind' => '$postings'
        }, {
          '$match' => {
            'postings.target_id' => @category.group.id,
            'postings.category_id' => @category.id
          }
        }, {
          '$project' => {
            '_id' => 1,
            'target_id' => '$postings.target_id',
            'category_id' => '$postings.category_id',
            'at' => '$postings.at'
          }
        }, {
          '$sort' => {
            'at' => -1
          }
        }, {
          '$skip' => @find_options[:page_size] * (@find_options[:page] - 1)
        }, {
          '$limit' =>  @find_options[:page_size]
        }).map { |i| i['_id'] }
    end
    
    def found_items
      #if @found_items.present?
        items = Post.includes(:owner, :author).find(found_ids)
        @found_items = found_ids.map { |i| items.find { |m| m.id == i } }
        #else
        #@found_items
        #end
    end
        
    def method_missing(method, *args, &block)
      found_items.send(method, *args, &block)
    end
  end
  
  class CategoryCollection

    def reorder(new_ids)
      if !@category.root?
        raise "Can only reorder from the root."
      end
      @category.group.post_category_order = [new_ids].flatten
    end

    # Add a subcategory with the given name
    #
    def add(name, format: :list, posting: :members)
      if !@category.root?
        raise "Can only add categories to the root."
      end
      c = @category.group.group_categories.build({ name: name, format: format, posting: posting, parent: @category }, GroupPostCategory)
      @category.group.post_category_order = [@category.group.post_category_order + [c.id]].flatten
      c
    end
    
    # Remove the category (passed) with the specified dependents strategy
    # 
    def remove(cat, dependents: :parent)
      self.remove_id(cat.id, dependents)
    end
    
    # Remove the category with the given id, handling dependents
    #
    def remove_id(id, dependents: :parent)
      cat = @category.descendants.select { |c| c.id == id }.first
      cat.remove(dependents: dependents)
    end
    
    # Inspect the categories for console
    #
    def inspect
      found_items.inspect
    end
    
    def ids
      found_items.map(&:id)
    end
    
    def ordered
      @category.group.post_category_order.map { |i| @category.children.find(i) }
    end
    
    private
    
    def initialize(cat, options = {})
      @category = cat
    end
    
    def found_items
      @category.children
    end
    
    def method_missing(method, *args, &block)
      found_items.send(method, *args, &block)
    end
  end
  
  
end
