class GroupWatchershipCollection < GroupRelationshipCollection
  
  undef :add, :remove
    
  protected
  
  def initialize(group, options = {})
    super(group, GroupWatchership, options)
  end
end
