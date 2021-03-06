# -*- encoding : utf-8 -*-
require 'builder'
require 'zip'

module Objects::Kml
  KMLNS='http://www.opengis.net/kml/2.2'

  def kml_document
    xml = Builder::XmlMarkup.new
    xml.instruct!
    xml.kml(
      'xmlns' => KMLNS,
      'xmlns:gx' => 'http://www.google.com/kml/ext/2.2',
      'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
      'xsi:schemaLocation' => 'http://www.opengis.net/kml/2.2 http://schemas.opengis.net/kml/2.2.0/ogckml22.xsd http://www.google.com/kml/ext/2.2 http://code.google.com/apis/kml/schema/kml22gx.xsd'
    ) do |xml|
      yield xml
    end
    xml.target!
  end

  def to_kmz(opts={})
    kml_to_kmz(self.to_kml(opts))
  end

  def extra_data(hash)
    xml = Builder::XmlMarkup.new
    hash.each do |key, value|
      xml.property(value.to_s, name: key)
    end
    xml.target!
  end

  def kml_to_kmz(kml)
    temp_file = Tempfile.new('kmlfile')
    begin
      Zip::OutputStream.open(temp_file.path) do |zos|
        zos.put_next_entry 'doc.kml'
        zos.puts kml
      end
      return File.read(temp_file.path)
    ensure
      temp_file.close
      temp_file.unlink
    end
  end

  def get_property(description, name, default = nil)
    regex = /<td>\s*?#{name}\s*?<\/td>\s*?<td>([^<]*)<\/td>/im
    match = regex.match(description)
    prop = if match.nil? then nil; else match[1].strip; end
    prop == '&lt;Null&gt;' || prop.nil? ? default : prop
  end

  module_function :get_property
end
