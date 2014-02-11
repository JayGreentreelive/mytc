class GroupCategoryCollection
  def initialize(group)
    @group = group
  end
  
  def inspect
    _ordered_items.inspect
  end
  
  def ids
    _ordered_items.map(&:id)
  end
  
  def stats
    _summary
  end
  
  def find(id)
    _items.find(id)
  end
  
  def find_by_slug(sl)
    _items.find_by(slugs: Utils::Slugger.slugify(sl))
  end
  
  def find_by_name(nm)
    _items.find_by(name: nm)
  end
  
  # Manipulation
  def add(name, posting: GroupCategory::POSTING_ADMINS, format: GroupCategory::FORMAT_LIST)
    new_category = @group.group_containers.build({ name: name, posting: posting, format: format }, GroupCategory)
    @group.category_order = [@group.category_order + [new_category.id]].flatten
    new_category
  end
  
  def remove(cat)
    raise "Cannot remove last category" if (_items.length <= 1)
    old_category = _items.find(cat.try(:id) || cat)
    @group.category_order = [@group.category_order - [old_category.id]].flatten
    old_category.destroy
  end
  
  def reorder(new_ids)
    cur_ids = _items.map(&:id)
    valid_ids = new_ids & cur_ids
    missing_ids = cur_ids - valid_ids
    
    @group.category_order = valid_ids + missing_ids
  end
  
  private
  
  def _items
    @group.group_containers.type(GroupCategory)
  end
  
  def _ordered_items
    @group.category_order.map { |category_id| _items.find(category_id) }
  end
  
  def _summary
    
    @_summary ||= begin
      pipeline = []
      
      # Finding Items in the category, first pass
      pipeline << {
        '$match' => {
          'postings' => {
            '$elemMatch' => {
              'target_id' => @group.id,
              'container_id' => {
                '$in' => ids
              }
            }
          }
        }
      }
      
      # Project just the id and postings array
      pipeline << {
        '$project' => {
          '_id' => 1,
          'postings' => 1
        }
      }
      
      # Unwind the postings
      pipeline << {
        '$unwind' => '$postings'
      }
      
      # Eliminate items that aren't in the proper group and cateogory
      pipeline << {
        '$match' => {
          'postings.target_id' => @group.id,
          'postings.container_id' => {
            '$in' => ids
          }
        }
      }
      
      # Project just the post id and the date it was posted
      pipeline << {
        '$project' => {
          '_id' => 1,
          'target_id' => '$postings.target_id',
          'container_id' => '$postings.container_id',
          'at' => '$postings.at'
        }
      }
      
      
      # Finally, group the data into a summary
      pipeline << {
        '$group' => {
          '_id' => {
            'target_id' => '$target_id',
            'container_id' => '$container_id'
          },
          'count' => {
            '$sum' => 1
          },
          'newest' => {
            '$max' => '$at'
          },
          'oldest' => {
            '$min' => '$at'
          }
        }
      }
      
      ret = Node.collection.aggregate(pipeline).first
      
      if ret
        ret
      else
        {}
      end
    end
  end
  
  def method_missing(method, *args, &block)
    _ordered_items.send(method, *args, &block)
  end
end