class GroupInvitationCollection < GroupRelationshipCollection
  
  protected
  
  def initialize(group, options = {})
    super(group, GroupInvitation, options)
  end
end
