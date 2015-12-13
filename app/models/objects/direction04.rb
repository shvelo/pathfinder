# -*- encoding : utf-8 -*-
require 'xml'
require 'csv'

class Objects::Direction04
  include Mongoid::Document
  include Mongoid::Search
  include Objects::Coordinate

  field :number, type: String

  belongs_to :region
  belongs_to :tp, class_name: 'Objects::Tp'
  belongs_to :substation, class_name: 'Objects::Substation'
  belongs_to :fider, class_name: 'Objects::Fider'
  has_many :pole04s, class_name: 'Objects::Pole04'
  has_many :fider04s, class_name: 'Objects::Fider04'

  search_in :name, :description, :fider, :tp => 'name'

  index({name: 1})
  index({region_id: 1})

  def self.get_or_create(number, tp)
    self.where(number: number).first || self.create(number: number, tp: tp, region: tp.region, fider: tp.fider, substation: tp.substation)
  end

  def self.decode(coded)
    %w(0 100 200 300 400 500 600 700 800 900)[coded.to_i] || coded
  end
end
