class GroupFollowershipCollection < GroupRelationshipCollection
  # TODO Don't add if member
  
  protected
  
  def initialize(group, options = {})
    super(group, ::GroupFollowership, options)
  end
end
