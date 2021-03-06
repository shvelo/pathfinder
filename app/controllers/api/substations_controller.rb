# -*- encoding : utf-8 -*-
class Api::SubstationsController < ApiController
  def index
    if params["bounds"] then
      substations = Objects::Substation.where(self.within_bounds(params["bounds"]))
    else
      substations = Objects::Substation.all
    end
    render json: (substations.map do |substation|
      { id: substation.id.to_s, lat: substation.lat, lng: substation.lng, name: substation.name }
    end)
  end

  def info
    @substation = Objects::Substation.find(params[:id])
    render layout: false
  end
end
