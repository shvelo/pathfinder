# -*- encoding : utf-8 -*-
class Objects::MapsController < ApplicationController
  def editor; @title='ობიექტების რედაქტირება' ; render layout: 'map' end
  def viewer; @title='ობიექტების რუკა' ; render layout: 'map' end

  def generate_images
    if request.post?
      ImageConversion.perform_async(params[:dir].to_ka(:all))
      redirect_to objects_generate_images_url(status: 'ok')
    else
      @title = 'გამოსახულებების გენერაცია'
      @root = Pathfinder::POLES_HOME
      @dirs = Dir.entries(@root).select {|entry| File.directory? File.join(@root) and !(entry =='.' || entry == '..') }
    end
  end

  protected
  def nav
    @nav=super
    @nav[@title]=nil
  end
end
