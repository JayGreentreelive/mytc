class GroupLibraryCategory < GroupCategory
  DEFAULT_NAME = 'New Folder'
  
  before_save :_ensure_posting_is_inherited
  
  def _ensure_posting_is_inherited
    if !self.root
      self.posting = POSTING_INHERIT
    end
  end
  
  
  # Return an ItemsProxy containing items limited by options
  #
  #def items(options = {})
  #  ItemCollection.new(self, options)
  #end

  # Returns a CategoryCollection   
  #
  def folders(options = {})
    FolderCollection.new(self, options)
  end

  
  # class ItemCollection
  #   def initialize(cat, options = {})
  #     @category = cat
  #     @find_options = options
  #   end
  #   
  #   def add();end
  #   def remove();end
  #   
  #   def inspect
  #     found_items.inspect
  #   end
  # 
  #   private
  #       
  #   def found_items
  #     @found_items ||= ['WHOO', 'NELLY', @find_options.to_s]
  #   end
  #       
  #   def method_missing(method, *args, &block)
  #     found_items.send(method, *args, &block)
  #   end
  # end
  
  class FolderCollection

    # Add a subfolder with the given name
    #
    def add(name)
      @category.group.group_categories.build({ name: name, posting: GroupCategory::POSTING_INHERIT, parent: @category }, GroupLibraryCategory)
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
    
    private
    
    def initialize(cat, options = {})
      @category = cat
    end
    
    def found_items
      @found_items ||= @category.children
    end
    
    def method_missing(method, *args, &block)
      found_items.send(method, *args, &block)
    end
  end
end
