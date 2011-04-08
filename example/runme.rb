# runme from the root source dir
#  you may need to require 'rubygems'

if ARGV.empty?
  puts "usage: jruby -rubygems example/runme.rb <path_to_batik_dir>"
end

require 'java'
$LOAD_PATH << './lib'
$CLASSPATH << ARGV.first

require 'sinatra'
require 'rack/batik'

use Rack::Batik::SVG::JPEG

get '*' do
  content_type 'image/svg+xml'
  SVG
end

SVG = %q{<svg width="100%" height="100%" version="1.1" 
  xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="orange_red" x1="0%" y1="0%" x2="100%" y2="0%">
      <stop offset="0%" style="stop-color:rgb(255,255,0);stop-opacity:1"/>
      <stop offset="100%" style="stop-color:rgb(255,0,0);stop-opacity:1"/>
    </linearGradient>
  </defs>
  <ellipse cx="200" cy="190" rx="85" ry="55"
    style="fill:url(#orange_red)"/>
</svg>}
