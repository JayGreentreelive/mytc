# Inspired by https://github.com/benedikt/mongoid-tree/blob/master/lib/mongoid/tree.rb
# Needed to work in and out of embedded documents

module Treeable
  extend ActiveSupport::Concern

  included do
    field :tree, type: Array, default: []
    
    #index({ tree: 1 }, { sparse: true })
    
    validate :_validate_tree
  end
  
  # Class Methods
  module ClassMethods
  end
  
  def root?
    self.parent.blank?
  end
  
  def root
    if self.tree.first
      _tree_query_base.where(id: self.tree.first).first
    else
      self
    end
  end
  
  def depth
    self.tree.length
  end
  
  def parent
    if tree.blank?
      nil
    else
      _tree_query_base.where(id: self.tree.last).first
    end
  end
  
  def parent=(par)
    self.tree_will_change!
    if par
      self.tree = par.tree + [par.id]
    else
      self.tree = []
    end
  end
  
  def children
    _tree_query_base.where(tree: self.tree + [self.id])
  end
  
  def leaf?
    self.children.blank?
  end
  
  def siblings
    self.siblings_and_self - [self]
  end
  
  def siblings_and_self
    self.root? ? [self] : _tree_query_base.where(tree: self.tree)
  end
  
  def sibling_of?(other)
    other.tree == self.tree
  end
  
  def ancestors
    _tree_query_base.in(id: self.tree)
  end
  
  def ancestors_and_self
    [self] + self.anscestors
  end
  
  def ancestor_of?(other)
    other.tree.include?(self.id)
  end
  
  def descendants
    _tree_query_base.where(tree: self.id)
  end
  
  def descendants_and_self
    [self] + self.descendants
  end
  
  def descendant_of?(other)
    self.tree.include?(other.id)
  end

  private

  def _tree_query_base
    if self.embedded?
      self.send(self.metadata.inverse).send(self.metadata.name).type(self.class)
    else
      self.class
    end
  end
  
  def _validate_tree
    if self.tree.present?
      if self.ancestors.length != self.tree.length
        errors.add(:tree, 'contains invalid parent ids')
      end
    end
  end
end





