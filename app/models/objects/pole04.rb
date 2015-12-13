# -*- encoding : utf-8 -*-
require 'xml'
require 'csv'

class Objects::Pole04
  include Mongoid::Document
  include Mongoid::Search
  include Objects::Coordinate
  include Objects::Kml

  field :kmlid, type: String
  field :name, type: String
  field :number, type: String
  field :height, type: Float
  field :pole_type, type: String
  field :description, type: String
  field :vertical_position, type: String
  field :oldness, type: String
  field :ankeruli, type: String
  field :lampioni, type: String
  field :owner, type: String
  field :internet, type: String
  field :street_light, type: String
  field :isolators, type: Array, default: []
  field :traverse, type: Array, default: []
  field :counters, type: Array, default: []

  belongs_to :region
  belongs_to :tp, class_name: 'Objects::Tp'
  belongs_to :fider, class_name: 'Objects::Fider'
  belongs_to :direction, class_name: 'Objects::Direction04'
  belongs_to :substation, class_name: 'Objects::Substation'

  search_in :name, :description, :fider, :tp => 'name'

  index({name: 1})
  index({region_id: 1})

  def traverse_s
    str = ''
    str += "კაუჭისებრი #{traverse[1]}, " unless traverse[1].nil?
    str += "კუთხოვანა ერთმაგი #{traverse[2]}, " unless traverse[2].nil?
    str += "კუთხოვანა ორმაგი #{traverse[3]}, " unless traverse[3].nil?
    str += "სხვა #{traverse[4]}" unless traverse[4].nil?
    str
  end

  def isolators_s
    str = ''
    str += "ფაიფური პატარა #{isolators[1]}, " unless isolators[1].nil?
    str += "ფაიფური დიდი #{isolators[2]}, " unless isolators[2].nil?
    str += "შუშა პატარა #{isolators[3]}, " unless isolators[3].nil?
    str += "შუშა დიდი #{isolators[4]}, " unless isolators[4].nil?
    str += "სხვა #{isolators[5]}" unless isolators[5].nil?
    str
  end

  def counters_s
    str = ''
    str += "ერთიანი #{counters[1]}, " unless counters[1].nil?
    str += "ორიანი #{counters[2]}, " unless counters[2].nil?
    str += "სამიანი #{counters[3]}, " unless counters[3].nil?
    str += "ოთხიანი #{counters[4]}, " unless counters[4].nil?
    str += "ხუთიანი #{counters[5]}" unless counters[5].nil?
    str += "ექვსიანი #{counters[6]}" unless counters[6].nil?
    str += "შვიდიანი #{counters[7]}" unless counters[7].nil?
    str += "ათიანი #{counters[8]}" unless counters[8].nil?
    str += "ცხრიანი #{counters[9]}" unless counters[9].nil?
    str += "სხვა #{counters[10]}" unless counters[10].nil?
    str
  end

  def self.from_kml(xml)
    parser=XML::Parser.string xml
    doc=parser.parse
    kmlns="kml:#{KMLNS}"
    placemarks=doc.child.find '//kml:Placemark', kmlns
    placemarks.each do |placemark|
      id = placemark.attributes['id']
      obj = Objects::Pole04.where(kmlid: id).first || Objects::Pole04.create(kmlid: id)
      # start description section
      descr = placemark.find('./kml:description', kmlns).first.content
      obj.name = Objects::Kml.get_property(descr, 'ბოძის id')
      obj.number = Objects::Kml.get_property(descr, 'ბოძის ნომერი')
      obj.height = Objects::Kml.get_property(descr, 'ბოძის სიმაღლე').to_f
      obj.pole_type = Objects::Kml.get_property(descr, 'ბოძის ტიპი', '').to_ka(:all)
      obj.ankeruli = Objects::Kml.get_property(descr, 'ანკერული', '').to_ka(:all)
      obj.oldness = Objects::Kml.get_property(descr, 'ხარისხრობრივი მდგომარეობა', '').to_ka(:all)
      obj.vertical_position = Objects::Kml.get_property(descr, 'ვერტიკალური მდგომარეობა', '').to_ka(:all)
      obj.owner = Objects::Kml.get_property(descr, 'მესაკუთრე', '').to_ka(:all)
      obj.lampioni = Objects::Kml.get_property(descr, 'ლამპიონის სამაგრი', '').to_ka(:all)
      obj.internet = Objects::Kml.get_property(descr, 'ინტერნეტი', '').to_ka(:all)
      obj.street_light = Objects::Kml.get_property(descr, 'გარე განათება', '').to_ka(:all)

      tpnumber = Objects::Kml.get_property(descr, 'ტრანსფორმატორის ნომერი')
      obj.tp = Objects::Tp.by_name(tpnumber) if tpnumber.present?

      dir_num = Objects::Direction04.decode(Objects::Kml.get_property(descr, 'მიმართულება'))
      obj.direction = Objects::Direction04.get_or_create(dir_num, obj.tp)

      description = Objects::Kml.get_property(descr, 'Note_')
      obj.description = description.to_ka(:all) if description.present?

      obj.region = obj.tp.region if obj.tp.present?
      obj.substation = obj.tp.substation if obj.tp.present?
      obj.fider = obj.tp.fider if obj.tp.present?

      # end of description section
      coord = placemark.find('./kml:Point/kml:coordinates', kmlns).first.content
      obj.set_coordinate(coord)
      obj.save
    end
  end

  def self.from_csv(csv)
    CSV.parse(csv, :headers => true) do |row|
      id = row['Pole_id'].gsub(',', '')
      quantity = row['Quantity'].to_i

      pole = Objects::Pole04.where({:name => id}).first

      unless pole.nil?
        if !row['Pole_T_type'].nil?
          traverse_type = row['Pole_T_type'].to_i
          pole.traverse[traverse_type] = quantity
        elsif !row['Pole_i_type'].nil?
          isolator_type = row['Pole_i_type'].to_i
          pole.isolators[isolator_type] = quantity
        elsif !row['Pole_co_type'].nil?
          counter_type = row['Pole_co_type'].to_i
          pole.counters[counter_type] = quantity
        end
        pole.save
      end
    end
  end
end
