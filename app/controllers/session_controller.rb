class SessionController < ApplicationController
  def login
    session[:current_user_id] = Person.find_by(eppn: 'bw16725@umbc.edu').id
    redirect_to :root
  end
  
  def logout
    reset_session
    redirect_to :root
  end
end
