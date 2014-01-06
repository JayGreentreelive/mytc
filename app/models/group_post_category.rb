class GroupPostCategory < GroupCategory
  #include Orderable
  
  DEFAULT_NAME = 'New Category'
  
  def items(options = {})
    ItemsProxy.new(self, options)
  end
  
  def categories
    CategoriesProxy.new(self)
  end
  
  class ItemsProxy < BasicObject
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
      @found_items ||= find_items
    end
        
    def find_items
      @find_options
      ['WHOO', 'NELLY', @find_options.to_s]
    end

    def method_missing(method, *args, &block)
      found_items.send(method, *args, &block)
    end
  end
  
  class CategoriesProxy < BasicObject
    def initialize(cat, options = {})
      @category = cat
    end
    
    def find_by_id(id)
      found_items.select { |i| i.id == id }.first
    end
    def add();end
    def remove();end
    
    def inspect
      found_items.inspect
    end
    
    private
    
    def found_items
      @found_items ||= find_items
    end
        
    def find_items
      @category.children
    end
    
    def method_missing(method, *args, &block)
      found_items.send(method, *args, &block)
    end
  end
end
