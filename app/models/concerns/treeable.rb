# Inspired by https://github.com/benedikt/mongoid-tree/blob/master/lib/mongoid/tree.rb
# Needed to work in and out of embedded documents

module Treeable
  extend ActiveSupport::Concern

  included do
    field :_path, type: Array, default: []
    
    #index({ _path: 1 }, { sparse: true })
    
    validate :_validate_path
  end
  
  # Class Methods
  module ClassMethods
  end
  
  def root?
    self.parent.blank?
  end
  
  def root
    if self._path.first
      _path_query_base.where(id: self._path.first).first
    else
      self
    end
  end
  
  def depth
    self._path.length
  end
  
  def parent
    if _path.blank?
      nil
    else
      _path_query_base.where(id: self._path.last).first
    end
  end
  
  def parent=(par)
    self._path_will_change!
    if par
      self._path = par._path + [par.id]
    else
      self._path = []
    end
  end
  
  def children
    _path_query_base.where(_path: self._path + [self.id])
  end
  
  def leaf?
    self.children.blank?
  end
  
  def siblings
    self.siblings_and_self.where(:id.ne => self.id)
    #self.siblings_and_self - [self]
  end
  
  def siblings_and_self
    _path_query_base.all(_path: self._path)
    #self.root? ? [self] : _path_query_base.where(_path: self._path)
  end
  
  def sibling_of?(other)
    other._path == self._path
  end
  
  def ancestors
    _path_query_base.in(id: self._path)
  end
  
  def ancestors_and_self
    _path_query_base.in(id: (self._path + [self.id]))
    #[self] + self.anscestors
  end
  
  def ancestor_of?(other)
    other._path.include?(self.id)
  end
  
  def descendants
    _path_query_base.all(_path: self._path + [self.id])
    #_path_query_base.where(_path: self.id)
  end
  
  def descendants_and_self
    _path_query_base.or({ :_path.all => (self._path + [self.id]) }, { :id => self.id })
    #[self] + self.descendants
  end
  
  def descendant_of?(other)
    self._path.include?(other.id)
  end

  private

  def _path_query_base
    if self.embedded?
      self.send(self.metadata.inverse).send(self.metadata.name).type(self.class)
    else
      self.class
    end
  end
  
  def _validate_path
    if self._path.present?
      if self.ancestors.length != self._path.length
        errors.add(:_path, 'contains invalid parent ids')
      end
    end
  end
end





