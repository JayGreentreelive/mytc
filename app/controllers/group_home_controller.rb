class GroupHomeController < ApplicationController
  
  before_action :setup_group, only: [:show]
  
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
  
  def setup_group
    @group = Group.get(params[:group_slug])
    
    if @group && @group.display_slug && @group.display_slug != params[:group_slug]
      redirect_to :group_slug => @group.display_slug
    end
    
  end
  
end
