module Utils
  class SlugCollection
    include Enumerable
    extend Forwardable
  
    def_delegator :@slugs, :each
    
    def initialize(obj, attr)
      @obj = obj
      @attr = attr
      @slugs = @obj.read_attribute(@attr)
    end
  
    def to_a
      @slugs
    end
  
    def set(sl)
      @obj.slugs_will_change!
      @obj.write_attribute(@attr, Utils::Slugger.slugify(sl).try(:uniq))
    end
  
    def add(sl)
      sl = Utils::Slugger.slugify(sl)
      @obj.slugs_will_change!
      @slugs << sl unless self.exists?(sl)
    end
  
    def remove(sl)
      @obj.slugs_will_change!
      @slugs.delete Utils::Slugger.slugify(sl) 
    end
  
    def exists?(sl)
      @slugs.include? Utils::Slugger.slugify(sl)
    end
  
    def inspect
      @slugs.inspect
    end
  end
end