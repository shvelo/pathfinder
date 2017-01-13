# -*- encoding : utf-8 -*-
require 'xml'

class Objects::Tower
  include Mongoid::Document
  include Mongoid::Search
  include Objects::Coordinate
  include Objects::Kml

  field :_id, type: String

  field :kmlid, type: String
  field :name, type: String
  field :category, type: String
  field :description, type: String
  field :region_name, type: String
  field :line_name, type: String
  belongs_to :region
  belongs_to :line, class_name: 'Objects::Line'
  field :linename, type: String

  search_in :name, :linename

  def info
    "გადამცემი ხაზი: #{linename};"
  end

  def self.from_kml(xml)
    parser=XML::Parser.string xml
    doc=parser.parse
    kmlns="kml:#{KMLNS}"
    placemarks=doc.child.find '//kml:Placemark', kmlns
    placemarks.each do |placemark|
      id=placemark.attributes['id']

      # description content
      descr = placemark.find('./kml:description', kmlns).first.content
      name = Objects::Kml.get_property(descr, 'ანძის_N')
      regname = Objects::Kml.get_property(descr, 'რეგიონი')
      category = Objects::Kml.get_property(descr, 'ანძის_ტიპი')
      category = nil if category == '&lt;Null&gt;'
      linename = Objects::Kml.get_property(descr, 'გადამცემი_ხაზი')
      # end of description section

      coord=placemark.find('./kml:Point/kml:coordinates', kmlns).first.content
      obj=Objects::Tower.where(kmlid: id).first || Objects::Tower.new(kmlid: id, _id: id)
      obj.name = name
      obj.region = Region.get_by_name(regname)
      obj.region_name = regname
      obj.set_coordinate(coord)
      obj.category = category
      obj.line = Objects::Line.where(name: linename, region: obj.region).first
      obj.linename = linename
      obj.save
    end
  end

  def self.rejoin_line(line)
    Objects::Tower.where(linename: line.name).each do |tower|
      tower.line = line
      tower.save
    end
  end
end
