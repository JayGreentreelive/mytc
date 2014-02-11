class GroupPostController < ApplicationController
  
  include GroupControl
  
  def index
    @category_id = params[:category_id].presence
  end
  
  def show
    
     
    
    @post = @group.posts.find(params[:post_id])
    
    if params[:list]
      list_group_id, list_cat_id = params[:list].split('-')
      @list_group = Group.find(list_group_id)
      if list_cat_id != 'all'
        @list_cat = @list_group.categories.find(list_cat_id)
        
        post_ids = @list_cat.posts.ids
        post_idx = post_ids.index(@post.id)
        
        #raise "#{post_ids}, #{post_idx}"
        
        @prev_post = Post.where(id: post_ids[post_idx - 1]).first if post_idx > 0
        @next_post = Post.where(id: post_ids[post_idx + 1]).first if post_idx < (post_ids.length - 1)
        
      else
        #@list_cat = @list_group.categories.find(list_cat_id)
        
        post_ids = @list_group.posts.ids
        post_idx = post_ids.index(@post.id)
        
        #raise "#{post_ids}, #{post_idx}"
        
        @prev_post = Post.where(id: post_ids[post_idx - 1]).first if post_idx > 0
        @next_post = Post.where(id: post_ids[post_idx + 1]).first if post_idx < (post_ids.length - 1)
      end
      
    end
    
    
  end
end
