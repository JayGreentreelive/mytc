class GroupFollowershipCollection < GroupRelationshipCollection
  # TODO Don't add if member
  
  protected
  
  def initialize(group)
    super(group, ::GroupFollowership)
  end
end
