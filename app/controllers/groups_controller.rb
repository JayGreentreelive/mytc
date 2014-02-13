class GroupsController < ApplicationController
  
  include PlaylistControl
  
  def index
    @letter = params[:letter].presence.try(:upcase) || 'A'
    
    if @letter == '#'
      query = /^[0-9]/
    else
      query = /^#{@letter}/i
    end
    
    @groups = Group.where(name: query)
    #UmbcPerson.where(last_name: @query).where(:umbc_affiliations.in => ['student', 'employee']).order_by(sorted_name: 1)
  end
  
end
