require 'xml'

class TpExtractionWorker
  include Sidekiq::Worker

  sidekiq_options retry: 2

  def perform(placemark_xml)
    placemark = XML::Parser.string(placemark_xml).parse.child

    id = placemark.attributes['id']
    obj = Objects::Tp.where(kmlid: id).first || Objects::Tp.new(kmlid: id)
    # name=placemark.find('name').first.content
    # start description section
    descr = placemark.find('description').first.content

    obj.region_name = Objects::Kml.get_property(descr, 'მუნიციპალიტეტი').to_ka(:all)
    return unless obj.region_name
    obj.region = Region.get_by_name(obj.region_name)
    return unless obj.region

    obj.city = Objects::Kml.get_property(descr, 'ქალაქი/დაბა/საკრებულო ქალაქი/დაბა/საკრებულო')
    obj.street = Objects::Kml.get_property(descr, 'ქუჩის დასახელება')
    obj.village = Objects::Kml.get_property(descr, 'სოფელი')
    obj.name = Objects::Kml.get_property(descr, 'ტრანსფორმატორის ნომერი')
    obj.tp_type = Objects::Kml.get_property(descr, 'ტრანსფორმატორის ტიპი')
    obj.picture_id = Objects::Kml.get_property(descr, 'სურათის ნომერი')
    obj.power = Objects::Kml.get_property(descr, 'სიმძლავრე').to_f
    obj.stores = Objects::Kml.get_property(descr, 'შენობის სართულიანობა')
    obj.count_high_voltage = Objects::Kml.get_property(descr, 'მაღალი ძაბვის ამომრთველი').to_i
    obj.count_low_voltage = Objects::Kml.get_property(descr, 'დაბალი ძაბვის ამომრთველი').to_i
    obj.owner = {"ked" => "კედ", "other" => "სხვა"}[Objects::Kml.get_property(descr, 'მესაკუთრე')]
    obj.address_code = Objects::Kml.get_property(descr, 'საკადასტრო კოდი')
    address = Objects::Kml.get_property(descr, 'მთლიანი მისამართი')
    obj.address = address.to_ka(:all) if address
    obj.substation_name = Objects::Kml.get_property(descr, 'ქვესადგური').to_ka(:all)

    return unless obj.substation_name

    obj.substation = Objects::Substation.where(name: obj.substation_name, region: obj.region).first
    return unless obj.substation
    linename = Objects::Kml.get_property(descr, 'ელექტრო გადამცემი ხაზი')
    obj.linename = linename.to_ka(:all)
    obj.description = Objects::Kml.get_property(descr, 'შენიშვნა')
    obj.fider_name = Objects::Kml.get_property(descr, 'ფიდერი').to_ka(:all)

    return unless obj.fider_name

    obj.fider = Objects::Fider.find_or_create(obj.fider_name, obj.substation.number, obj.region)
    # end of description section
    coord = placemark.find('Point/coordinates').first.content
    obj.set_coordinate(coord)
    obj.save
  end

end