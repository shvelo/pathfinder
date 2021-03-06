# -*- encoding : utf-8 -*-
require 'zip'

class Objects::Direction04sController < ApplicationController
  include Objects::Kml

  def index
    rel = Objects::Direction04.asc(:region_name, :tp_name, :number)
    @search = search_params
    if @search.present?
      rel = rel.where(name: @search[:name].mongonize) if @search[:name].present?
      rel = rel.where(region_id: @search[:region]) if @search[:region].present?
      rel = rel.where(number: @search[:number]) if @search[:number].present?
      rel = rel.where(tp_name: @search[:tp]) if @search[:tp].present?
    end

    respond_to do |format|
      format.html{ @title = '0.4კვ ხაზები'; @fiders = rel.paginate(per_page:10, page: params[:page]) }
      format.xlsx{ @fiders = rel }
      format.kmz do
        @fiders = rel
        kml = kml_document do |xml|
          xml.Document(id: 'fiders') do
            @fiders.each { |fider| to.to_kml(xml) }
          end
        end
        send_data kml_to_kmz(kml), filename: 'fiders.kmz'
      end
    end
  end

  def show
    @title='მიმართულება'
    @fider=Objects::Direction04.find(params[:id])
  end

  def find
    @title = 'მიმართულება'
    @fider = Objects::Direction04.where(name: params[:name]).first
    if @fider
      render action: 'show'
    else
      render text: "0.4კვ ხაზი \"#{params[:name]}\" ვერ მოიძებნა"
    end
  end

  protected

  def nav
    @nav=super
    @nav['0.4კვ ხაზები'] = objects_direction04s_url
    @nav[@title]=nil unless ['index'].include?(action_name)
  end

  def login_required; true end
  def permission_required; not current_user.admin? end

end
