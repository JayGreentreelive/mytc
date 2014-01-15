class GroupRelationshipCollection
  
  def entity_ids
    _memberships.map(&:entity_id)
  end
  
  def entities
    if _memberships.length > 0
      _memberships.includes(:entity).map(&:entity)
    else
      []
    end
  end
  
  def entity(ent)
    _memberships.where(entity_id: ent.id).first
  end
  
  def has_entity?(ent)
    entity(ent) != nil
  end
  
  def add(ent, options = {})
    mem = entity(ent)
    
    if mem
      mem
    else
      _relationships.build(options.merge({ entity: ent }), @klass)
    end
  end
  
  def remove(id)
    mem = _memberships.find(id)
    if mem
      _relationships.delete(mem)
    end
  end
    
  protected
    
  def _relationships
    @group.group_relationships
  end
  
  def _memberships
    _relationships.type(@klass._types)
  end
  
  def initialize(group, klass, options = {})
    @group = group
    @klass = klass
    @options = options
  end
      
  def method_missing(method, *args, &block)
    _memberships.send(method, *args, &block)
  end
end

