module PlaylistControl
  extend ActiveSupport::Concern

  included do
    before_action :setup_playlist
  end

  # Instance Methods  
  def setup_playlist
    if params[:pl].present?
      #@playlist = Playlist.new(@user)
      @playlist = @user
    end
  end
end