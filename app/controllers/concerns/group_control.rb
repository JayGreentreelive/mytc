module GroupControl
  extend ActiveSupport::Concern

  included do
    before_action :setup_group
  end

  # Instance Methods  
  def setup_group
    @group = Group.get(params[:group_slug])
    
    if @group && @group.display_slug && @group.display_slug != params[:group_slug]
      redirect_to :group_slug => @group.display_slug
    end
  end
end