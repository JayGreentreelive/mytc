class GroupMembershipCollection < GroupRelationshipCollection
  
  # TODO Turn followers into members
  # TODO Don't allow last member to leave
  
  protected
  
  def initialize(group, options = {})
    super(group, GroupMembership, options)
  end
end
