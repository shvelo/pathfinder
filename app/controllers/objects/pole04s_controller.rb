# -*- encoding : utf-8 -*-
require 'zip'

class Objects::Pole04sController < ApplicationController
  include Objects::Kml

  def index
    rel=Objects::Pole04.asc(:region_name, :tp_name, :fider_id, :name)
    @search = search_params
    if @search.present?
      rel = rel.where(number: @search[:number].mongonize) if @search[:number].present?
      rel = rel.where(region_id: @search[:region]) if @search[:region].present?
      rel = rel.where(substation_id: @search[:substation]) if @search[:substation].present?
      rel = rel.where(fider_id: @search[:fider]) if @search[:fider].present?
      rel = rel.where(direction: @search[:direction]) if @search[:direction].present?
      rel = rel.where(tp_name: @search[:tp]) if @search[:tp].present?
    end

    respond_to do |format|
      format.html { @title='0.4კვ ბოძები'; @poles=rel.paginate(per_page: 10, page: params[:page]) }
      format.xlsx { @poles=rel }
      format.kmz do
        @poles=rel
        kml = kml_document do |xml|
          xml.Document(id: 'poles') do
            @poles.each { |pole| to.to_kml(xml) }
          end
        end
        send_data kml_to_kmz(kml), filename: 'poles.kmz'
      end
    end
  end

  def upload
    @title='ფაილის ატვირთვა: 0.4კვ ბოძები'
    if request.post?
      f=params[:data].original_filename
      delete_old = params[:delete_old]
      case File.extname(f).downcase
        when '.kmz' then
          upload_kmz(params[:data].tempfile, delete_old)
        when '.kml' then
          upload_kml(params[:data].tempfile, delete_old)
        when '.txt' then
          upload_txt(params[:data].tempfile)
        else
          raise 'არასწორი ფორმატი'
      end
      redirect_to objects_pole04s_url, notice: 'მონაცემების ატვირთვა დაწყებულია. შეამოწმეთ მიმდინარე დავალებათა გვერდი'
    end
  end

  def show
    @title='0.4კვ ბოძი'
    @pole=Objects::Pole04.find(params[:id])
  end

  protected

  def nav
    @nav=super
    @nav['0.4კვ ბოძები']=objects_pole04s_url
    @nav[@title]=nil unless ['index'].include?(action_name)
  end

  def login_required;
    true
  end

  def permission_required;
    not current_user.admin?
  end

  private

  def upload_kmz(file, delete_old)
    Pole04sUploadWorker.perform_async(file.path, delete_old)
  end

  def upload_txt(file)
    Pole04sTxtUploadWorker.perform_async(file.path)
  end
end
