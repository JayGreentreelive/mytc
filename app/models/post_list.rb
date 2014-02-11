class PostList
  def initialize()
    @list_options = {}
  end
  
  def inspect
    _found_items.inspect
  end
  
  def find(id)
    @list_options[:find_id] = id || -1
    ret = _found_items.first 
    unless ret
      raise Mongoid::Errors::DocumentNotFound.new(Post, @list_options)
    end
    ret
  end
  
  def find_by_slug(sl)
    @list_options[:find_slug] = Utils::Slugger.slugify(sl) || -1
    ret = _found_items.first 
    unless ret
      raise Mongoid::Errors::DocumentNotFound.new(Post, @list_options)
    end
    ret
  end
  
  def posted_after(dt)
    @list_options[:posted_after] = dt.utc
    self
  end
  
  def group(group)
    @list_options[:group] = group
    self.dup
  end
  
  def category(cat)
    @list_options[:category] = cat
    self
  end
  
  def page(page_number, page_size = 10)
    @list_options[:page_number] = page_number
    @list_options[:page_size] = page_size
    self
  end
  
  def includes(inc)
    @list_options[:includes] = inc
    self
  end
  
  def ids
    _summary[:ids]
  end

  def count
    _summary[:count]
  end
  
  def newest
    _summary[:newest]
  end
  
  def oldest
    _summary[:oldest]
  end  
  
  def stats
    _summary
  end  
  
  def reset
    @_summary = {}
  end
  
  private
  
  def _found_items
    if @list_options[:includes]
      items_arr = Post.includes(@list_options[:includes]).find(ids)
    else
      items_arr = Post.find(ids)
    end
    ids.map { |i| items_arr.find { |m| m.id == i } }
  end
  
  def _summary
    
    @_summary ||= {}
    
    if @list_options.blank?
      raise ArgumentError.new("You must specify at least one criteria")
    end
    
    @_summary[@list_options.hash] ||= begin
      pipeline = []

      if @list_options[:group]
        # Ensure the group is a Group object
        if @list_options[:group].try(:id)
          group = @list_options[:group]
        else
          group = Group.find(@list_options[:group])
        end
      
        # Set the categories we want, or use all of them
        if @list_options[:category]
          cats = [@list_options[:category]].flatten
        else
          cats = [group.categories.ids].flatten
        end
        cats = cats.map { |c| c.try(:id) ? c : group.categories.find(c) }
      end
      
      if @list_options[:find_id]
        pipeline << {
          '$match' => {
            '_id' => @list_options[:find_id]
          }
        }
      elsif @list_options[:find_slug]
        pipeline << {
          '$match' => {
            'slugs' => @list_options[:find_slug]
          }
        }
      end
      
      # Finding Items in the category, first pass
      if @list_options[:group]
        pipeline << {
          '$match' => {
            'postings' => {
              '$elemMatch' => {
                'target_id' => @list_options[:group].id,
                'container_id' => {
                  '$in' => cats.map(&:id)
                }
              }
            }
          }
        }
      end
      
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
      if @list_options[:group]
        pipeline << {
          '$match' => {
            'postings.target_id' => @list_options[:group].id,
            'postings.container_id' => {
              '$in' => cats.map(&:id)
            }
          }
        }
      end
      
      # Project just the post id and the date it was posted
      pipeline << {
        '$project' => {
          '_id' => 1,
          'at' => '$postings.at'
        }
      }
      
      if @list_options[:posted_after]
        pipeline << {
          '$match' => {
            'at' => {
              '$gte' => @list_options[:posted_after]
            }
          }
        }
      end
      
      # Now sort by the posting at, newest first
      pipeline << {
        '$sort' => {
          'at' => -1
        }
      }
      
      if @list_options[:page_number]
        pipeline << {
          '$skip' => ((@list_options[:page_number] - 1) * @list_options[:page_size])
        }
        pipeline << {
          '$limit' => @list_options[:page_size]
        }
      end
      
      # Finally, group the data into a summary
      pipeline << {
        '$group' => {
          '_id' => 1,
          'ids' => {
            '$push' => '$_id'
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
      
      ret = Post.collection.aggregate(pipeline).first
      
      if ret
        { ids: ret['ids'], count: ret['count'], newest: ret['newest'], oldest: ret['oldest'] }
      else
        { ids: [], count: 0, newest: nil, oldest: nil }
      end
    end
  end
      
  def method_missing(method, *args, &block)
    _found_items.send(method, *args, &block)
  end
end