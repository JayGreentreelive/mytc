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
      @category = cat
      @find_options = options
    end
    
    def add();end
    def remove();end
    
    def inspect
      found_items.inspect
    end

    private
        
    def found_items
      @found_items ||= ['WHOO', 'NELLY', @find_options.to_s]
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
    
    private
    
    def initialize(cat, options = {})
      @category = cat
    end
    
    def found_items
      @found_items ||= @category.group.post_category_order.map { |i| @category.children.find(i) }
    end
    
    def method_missing(method, *args, &block)
      found_items.send(method, *args, &block)
    end
  end
  
  
end
