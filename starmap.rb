# coding: utf-8
require 'matrix'
require 'math/tau'
require 'ruby-units'

include Math

R2 = sqrt 2
R3 = sqrt 3
R6 = sqrt 6
M=Matrix[[R3, 0, -R3],[1, 2, 1], [R2, -R2, R2]]/R6

F=Matrix[[1, 0, 0], [0, 1, 0], [0, 0, 0]]

v=[-100,0,100]

GALACTIC_NORTH_RA = TAU*192.85/360.0
GALACTIC_NORTH_DEC = TAU*(27+77.0/600.0)/360.0
GALACTIC_CENTRE_RA = TAU*266.4/360.0
GALACTIC_CENTRE_DEC = TAU*(-28.929656275)/360.0

def celestial_to_glactic(ra, dec, *other)
  # From http://terraformers.info/files/galactic.pdf
  gal_lat = asin(sin(dec)*sin(GALACTIC_NORTH_DEC)+cos(dec)*cos(GALACTIC_NORTH_DEC)*cos(ra-GALACTIC_NORTH_RA))
  j = (sin(dec)*cos(GALACTIC_NORTH_DEC)-cos(dec)*sin(GALACTIC_NORTH_DEC)*cos(ra-GALACTIC_NORTH_RA))/cos(gal_lat)
  k = asin(cos(dec)*sin(ra-GALACTIC_NORTH_RA)/cos(gal_lat))
  q = acos(sin(GALACTIC_CENTRE_DEC)/cos(GALACTIC_NORTH_DEC)) # Should make this a constant
  gal_lon = j<0 ? q+k : q-k
  return [gal_lat, gal_lon, *other]
end

def celestial_to_glactic_deg(ra, dec, *other)
  rad_to_deg_v(celestial_to_glactic(deg_to_rad(ra), deg_to_rad(dec), *other))
end

def spherical_to_cartesian(lat, lon, dist)
  x = dist*cos(lat)*sin(lon) # +x Right when facing centre (With north up?)
  y = dist*cos(lat)*cos(lon) # +y Toward centre
  z = dist*sin(lat) # +z Galactic North
  return [x,y,z]
end

def deg_to_rad(degrees)
  degrees*TAU/360
end

def ra_to_rad(h, m=0, s=0)
  h+m/60.0+s/60.0/60.0
end

def rad_to_deg(radians)
  radians*360/TAU
end

def deg_to_rad_v(v)
  v.take(2).map{|a| deg_to_rad(a)}+v.drop(2)
end

def ra_to_rad_v(v)
  [ra_to_rad(*v[0]), deg_to_rad(v[1]), *v.drop(2)]
end

def rad_to_deg_v(v)
  v.take(2).map{|a| rad_to_deg(a)}+v.drop(2)
end

ANGLE_REGEXP = /(?<sign>[\+-])?(?:(?<deg>\d+(?:\.\d+|\/\d+)?)\s?(?:deg|d|°)\s?)?(?:(?<arcmin>\d+(?:\.\d+|\/\d+)?)\s?(?:min|m|amin|am|'|′)\s?)?(?:(?<arcsec>\d+(?:\.\d+|\/\d+)?)\s?(?:sec|s|asec|as|"|''|″|′′)\s?)?(?<dir>N|S|E|W|(?i:CW|CCW|ACW))?/

RubyUnits::Unit.define('arcminute') do |arcmin|
  arcmin.definition    = RubyUnits::Unit.new('1/60 deg')
  arcmin.aliases       = %w[arcmin]
end

RubyUnits::Unit.define('arcsecond') do |arcsec|
  arcsec.definition    = RubyUnits::Unit.new('1/60 arcmin')
  arcsec.aliases       = %w[arcsec]
end

def parse_dms(s)
  m = ANGLE_REGEXP.match s
  sign = 1
  sign *= -1 unless m["dir"].nil? or ['N', 'E', 'CCW', 'ACW'].include? m["dir"].upcase
  sign *= -1 unless m["sign"].nil? or m["sign"]=='+'
  angle = ["deg", "arcmin", "arcsec"].reverse.find_all do |unit|
    not m[unit].nil?
  end.map do |unit|
    "#{m[unit]} #{unit}".to_unit
  end.inject(0){|sum,x| sum + x }
  return angle*sign
end

def to_dms(theta, directions=nil, formats=nil)
  direction = nil
  unless directions.nil?
    formats="%<deg>0.0f° %<arcmin>0.0f′ %<arcsec>0.0f″ %<direction>s" if formats.nil?
    direction = directions[theta<=>0]
    theta = theta.abs
  else
    formats="%<deg>0.0f° %<arcmin>0.0f′ %<arcsec>0.0f″" if formats.nil?
  end
  sign = theta <=> 0
  theta = theta.abs
  arcsec_theta = theta.convert_to('arcsec').floor.scalar
  arcsec = arcsec_theta % 60
  arcmin = (arcsec_theta / 60 % 60).floor
  deg = (arcsec_theta / 3600).floor
  if sign<0
    if deg == 0
      deg =-0.0
    else
      deg *=-1
    end
  end
  #puts formats % {:deg=>deg, :arcmin=>arcmin, :arcsec=>arcsec, :direction=>direction}
end

to_dms("7777 arcsec".to_unit)

#p rad_to_deg_v(celestial_to_glactic(*ra_to_rad_v([[19,32,21.3],69+39.0/60+5.6/60/60, 18.77])))

#p celestial_to_glactic(293.089959417/360*TAU, 69.6611765/360*TAU, 18.77)
#p celestial_to_glactic(293.089959417/360*TAU, 69.6611765/360*TAU, 512)

puts <<EOS
<?xml version="1.0" encoding="UTF-8" ?>
<svg xmlns="http://www.w3.org/2000/svg" version="1.1">
EOS

STARS = [
  {name: "Sol", location: Vector[0,0,0]},
  {name: "Manticore", location: Vector[65,77,502]},
]

STARS.each do |s|
  p = s[:location]
  p2 = M*p
  pb2 = M*F*p
  puts <<EOS
  <line x1="#{p2[0]}" y1="#{p2[1]}" x2="#{pb2[0]}" y2="#{pb2[1]}" style="stroke:rgb(255,0,0);stroke-width:1" />
  <circle cx="#{p2[0]}" cy="#{p2[1]}" r='1" fill="orange" />"
EOS

end


puts <<EOS
</svg>
EOS
