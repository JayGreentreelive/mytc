class GroupMembershipCollection < GroupRelationshipCollection
  
  # TODO Turn followers into members
  # TODO Don't allow last member to leave
  
  protected
  
  def initialize(group, options = {})    
    @officer = options[:officer]
    @admin = options[:admin]
    super(group, GroupMembership, options)
  end
  
  def _memberships
    rel = super
    
    if @officer == true
      rel = rel.where(officer: true)
    elsif @officer == false
      rel = rel.where(:officer.ne => true)
    end
    
    if @admin == true
      rel = rel.where(admin: true)
    elsif @admin == false
      rel = rel.where(:admin.ne => true)
    end
    
    rel
  end
end
