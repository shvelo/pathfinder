require 'xml'
require 'digest/sha1'

class Pole04ExtractionWorker
  include Sidekiq::Worker

  def perform(placemark_xml)
    placemark = XML::Parser.string(placemark_xml).parse.child
    descr = placemark.find('description').first.content

    number = Objects::Kml.get_property(descr, 'ბოძის ნომერი') || ""
    poleid = Objects::Kml.get_property(descr, 'ბოძის id') || ""
    tpnumber = Objects::Kml.get_property(descr, 'ტრანსფორმატორის ნომერი') || ""
    region_name = Objects::Kml.get_property(descr, 'მუნიციპალიტეტი') || ""
    dir_num = Objects::Kml.get_property(descr, 'მიმართულება') || ""

    id = Digest::SHA1.hexdigest(dir_num + number + poleid + tpnumber + region_name)
    logger.info("Uploading Pole04 #{id}")

    obj = Objects::Pole04.where(_id: id).first || Objects::Pole04.new(_id: id)

    # start description section
    obj.number = number

    obj.poleid = poleid
    obj.name = number

    obj.height = Objects::Kml.get_property(descr, 'ბოძის სიმაღლე').to_f
    obj.pole_type = Objects::Kml.get_property(descr, 'ბოძის ტიპი', '').to_ka(:all)
    obj.ankeruli = Objects::Kml.get_property(descr, 'ანკერული', '').to_ka(:all)
    obj.oldness = Objects::Kml.get_property(descr, 'ხარისხრობრივი მდგომარეობა', '').to_ka(:all)
    obj.vertical_position = Objects::Kml.get_property(descr, 'ვერტიკალური მდგომარეობა', '').to_ka(:all)
    obj.owner = Objects::Kml.get_property(descr, 'მესაკუთრე', '').to_ka(:all)
    obj.lampioni = Objects::Kml.get_property(descr, 'ლამპიონის სამაგრი', '').to_ka(:all)
    obj.internet = Objects::Kml.get_property(descr, 'ინტერნეტი', '').to_ka(:all)
    obj.street_light = Objects::Kml.get_property(descr, 'გარე განათება', '').to_ka(:all)

    begin
      obj.tp = Objects::Tp.find_by(name: tpnumber) unless tpnumber.blank?
    rescue
      logger.error("Invalid TP number #{tpnumber} for Pole04 #{id}")
      return
    end

    obj.tp_name = obj.tp.name
    description = Objects::Kml.get_property(descr, 'Note_')
    obj.description = description.to_ka(:all) if description.present?
    obj.region = obj.tp.region
    obj.region = Region.get_by_name(region_name) if obj.region.blank?
    obj.region_name = obj.region.name if obj.region.present?
    obj.direction = Objects::Direction04.decode(dir_num)
    obj.direction04 = Objects::Direction04.get_or_create(obj.region, dir_num, obj.tp)
    obj.substation = obj.tp.substation
    obj.substation_name = obj.substation.name if obj.substation.present?
    obj.fider = obj.tp.fider
    obj.fider_name = obj.fider.name if obj.fider.present?
    # end of description section

    coord = placemark.find('Point/coordinates').first.content
    obj.set_coordinate(coord)
    obj.save
  end

end
