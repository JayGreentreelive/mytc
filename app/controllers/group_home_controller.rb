class GroupHomeController < ApplicationController
  
  before_action :setup_group, only: [:show, :category, :post_show]
  
  def index
    @groups = Group.order_by(status: 1).all
    @group_count = @groups.count
    @page = params[:page].presence.try(:to_i) || 1
    #render stream: true
  end
  
  def show
    #render stream: true
  end
  
  def frog
    render text: 'Successfully Frogged'
  end
  
  def category

    @page_size = 50
    @page = params[:page].presence || 1
    @cat = @group.posts.categories.find(params[:category_id])
  end
  
  def post_show
    @post = Post.where(owner_id: @group.id).find(params[:post_id])
  end
  
  def setup_group
    @group = Group.get(params[:group_slug])
    
    if @group && @group.display_slug && @group.display_slug != params[:group_slug]
      redirect_to :group_slug => @group.display_slug
    end
    
  end
  
end
