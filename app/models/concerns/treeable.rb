# Inspired by https://github.com/benedikt/mongoid-tree/blob/master/lib/mongoid/tree.rb
# Needed to work in and out of embedded documents

module Treeable
  extend ActiveSupport::Concern

  included do
    field :path, type: Array, default: []    
    index({ path: 1 }, { sparse: true })
    validate :_validate_path
  end
  
  # Class Methods
  module ClassMethods
  end
  
  def root?
    self.parent.blank?
  end
  
  def root
    if self.path.first
      _path_query_base.where(id: self.path.first).first
    else
      self
    end
  end
  
  def depth
    self.path.length
  end
  
  def parent
    if path.blank?
      nil
    else
      _path_query_base.where(id: self.path.last).first
    end
  end
  
  def parent=(par)
    self.path_will_change!
    if par
      self.path = par.path + [par.id]
    else
      self.path = []
    end
  end
  
  def children
    _path_query_base.where(path: self.path + [self.id])
  end
  
  def leaf?
    self.children.blank?
  end
  
  def siblings
    self.siblings_and_self.where(:id.ne => self.id)
  end
  
  def siblings_and_self
    _path_query_base.all(path: self.path)
  end
  
  def sibling_of?(other)
    other.path == self.path
  end
  
  def ancestors
    _path_query_base.in(id: self.path)
  end
  
  def ancestors_and_self
    _path_query_base.in(id: (self.path + [self.id]))
  end
  
  def ancestor_of?(other)
    other.path.include?(self.id)
  end
  
  def descendants
    _path_query_base.all(path: self.path + [self.id])
  end
  
  def descendants_and_self
    _path_query_base.or({ :path.all => (self.path + [self.id]) }, { :id => self.id })
    #[self] + self.descendants
  end
  
  def descendant_of?(other)
    self.path.include?(other.id)
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
    if self.path.present?
      if self.ancestors.length != self.path.length
        errors.add(:path, 'contains invalid parent ids')
      end
    end
  end
end





