class GroupHomeController < ApplicationController
  
  include GroupControl
  
  def index  
    @people_count = @group.group_relationships.count
    @post_count = @group.posts.count
  end  
end
