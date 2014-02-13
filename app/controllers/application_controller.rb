class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  
  # Expire Everything, for development
  before_action do
    expires_now
  end
  
  before_action :setup_active_user
  
  
  def setup_active_user
    if session[:current_user_id]
      @user = User.new(session[:current_user_id])
    else
      @user = User.new
    end
    #ucount = UmbcPerson.where(umbc_affiliations: 'undergraduate-student').count
    @user = Person.get('my3-user-3')
    #UmbcPerson.where(umbc_affiliations: 'undergraduate-student').offset(SecureRandom.random_number(ucount)).first
  end
  

  
end
