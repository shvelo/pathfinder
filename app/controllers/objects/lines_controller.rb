# -*- encoding : utf-8 -*-
require 'zip'
require 'roo'

class Objects::LinesController < ApplicationController
  include Objects::Kml

  def index
    rel = Objects::Line.asc(:name)
    @search = search_params
    if @search.present?
      rel = rel.where(name: @search[:name].mongonize) if @search[:name].present?
      rel = rel.where(region_id: @search[:region]) if @search[:region].present?
      rel = rel.where(kmlid: @search[:kmlid].mongonize) if @search[:kmlid].present?
      rel = rel.where(direction: @search[:direction].mongonize) if @search[:direction].present?
    end
    respond_to do |format|
      format.html { @title='გადამცემი ხაზები'; @lines = rel.asc(:name).paginate(per_page: 10, page: params[:page]) }
      format.xlsx { @lines = rel.asc(:name) }
      format.kmz do
        @lines = rel
        kml = kml_document do |xml|
          xml.Document(id: 'lines') do
            @lines.each { |line| line.to_kml(xml) }
          end
        end
        send_data kml_to_kmz(kml), filename: 'lines.kmz'
      end
    end
  end

  def upload
    @title='ფაილის ატვირთვა'
    if request.post?
      f = params[:data].original_filename
      delete_old = params[:delete_old]
      case File.extname(f).downcase
        when '.kmz' then
          upload_kmz(params[:data].tempfile, delete_old)
        when '.kml' then
          upload_kml(params[:data].tempfile)
        when '.xlsx' then
          upload_xlsx(params[:data].tempfile)
        else
          raise 'არასწორი ფორმატი'
      end
      redirect_to objects_lines_url, notice: 'მონაცემების ატვირთვა დაწყებულია. შეამოწმეთ მიმდინარე დავალებათა გვერდი.'
    end
  end

  def show
    @title='გადამცემი ხაზის თვისებები'
    @line=Objects::Line.find(params[:id])
  end

  protected
  def nav
    @nav = super
    @nav['გადამცემი ხაზები'] = objects_lines_url
    @nav[@title] = nil unless ['index'].include?(action_name)
  end

  def login_required;
    true
  end

  def permission_required;
    not current_user.admin?
  end

  private

  def upload_kmz(file, delete_old)
    LinesUploadWorker.perform_async(file.path, delete_old)
  end

  def upload_xlsx(file)
    XLSConverter.perform_async('Objects::Line', file.path.to_s)
  end
end
