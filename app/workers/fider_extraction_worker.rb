require 'xml'
require 'digest/sha1'

class FiderExtractionWorker
  include Sidekiq::Worker

  def perform(placemark_xml)
    placemark = XML::Parser.string(placemark_xml).parse.child

    descr = placemark.find('description').first.content

    name = Objects::Kml.get_property(descr, 'ფიდერი').to_ka(:all) || ""
    substation_number = Objects::Kml.get_property(descr, 'ქვესადგურის ნომერი') || ""
    region_name = Objects::Kml.get_property(descr, 'მუნიციპალიტეტი').to_ka(:all) || ""
    region = Region.get_by_name(region_name) || ""
    linestart = Objects::Kml.get_property(descr, 'საწყისი ბოძი') || ""
    lineend = Objects::Kml.get_property(descr, 'ბოძამდე') || ""

    id = Digest::SHA1.hexdigest(name + substation_number + region_name)
    line_id = Digest::SHA1.hexdigest(name + linestart + lineend + id + substation_number + region_name)

    logger.info("Processing line #{line_id} for fider #{id}")

    fider = Objects::Fider.where(_id: id).first || Objects::Fider.new(_id: id)

    line = Objects::FiderLine.where(_id: line_id).first || Objects::FiderLine.new(fider: fider, _id: line_id)
    line.fider_name = name
    line.start = linestart
    line.end = lineend
    line.cable_type = Objects::Kml.get_property(descr, 'სადენის ტიპი')
    line.cable_area = Objects::Kml.get_property(descr, 'სადენის კვეთი')
    line.underground = Objects::Kml.get_property(descr, 'მიწისქვეშა კაბელი')
    line.quro = Objects::Kml.get_property(descr, 'ქურო')
    line.description = Objects::Kml.get_property(descr, 'შენიშვნა')
    line.region = region
    line.voltage = Objects::Kml.get_property(descr, 'ფიდერის ძაბვა')
    line.linename = Objects::Kml.get_property(descr, 'ელ, გადამცემი ხაზი').to_ka(:all)
    line.substation_number = substation_number

    coords = placemark.find('MultiGeometry/LineString/coordinates').first.content
    coords = coords.split(' ')

    coords.each do |coord|
      point = line.points.new(line: line)
      point.set_coordinate(coord)
    end

    line.set_coordinate(coords[coords.size/2])
    line.calc_length!

    fider.name = name
    fider.linename = line.linename
    fider.line = Objects::Line.where(name: fider.linename, region: region).first
    fider.set_coordinate(coords[coords.size/2])
    fider.region = region
    fider.region_name = region_name
    fider.substation_number = substation_number
    fider.substation = Objects::Substation.where(number: fider.substation_number, region: fider.region).first
    fider.substation_name = fider.substation.name if fider.substation.present?

    fider.save
    line.save

    logger.info("Saved fider #{id}")
  end
end
