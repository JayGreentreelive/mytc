class GroupsController < ApplicationController
  
  include PlaylistControl
  
  def index
    @letter = params[:letter].presence.try(:upcase) || 'A'
    
    if @letter == '#'
      @query = /^[0-9]/
    else
      @query = /^#{@letter}/i
    end
    
    @groups = UmbcPerson.where(last_name: @query).where(:umbc_affiliations.in => ['staff', 'faculty']).where(:avatar_url.exists => true).order_by(sorted_name: 1)
    
    @group = @user
  end
  
end
