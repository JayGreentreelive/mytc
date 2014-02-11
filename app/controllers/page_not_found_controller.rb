class PageNotFoundController < ApplicationController
  
  def legacy_group_news
    group = Group.get(params[:group_slug])    
    new_cat = group.posts.categories.find_by(slugs: 'my3-news')
    
    id = params[:id].presence
    
    if id
      new_post = new_cat.items.find_by_slug("my3-news-#{id}")
      redirect_to group_post_path(group, new_post)
    else
      redirect_to group_post_category_path(group, new_cat)
    end
  end
  
  
  
end
