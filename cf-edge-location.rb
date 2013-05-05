# -*- encoding: utf-8 -*-
#
require 'rubygems'
require 'netaddr'
require 'pp'
require 'mechanize'
require 'resolv'
require 'net/ping'

require 'getoptlong'

opts = GetoptLong.new(
  [ '--help',      '-h', GetoptLong::NO_ARGUMENT ],
  [ '--debug'   ,  '-d', GetoptLong::NO_ARGUMENT ],
  [ '--full-scan', '-f', GetoptLong::NO_ARGUMENT ]
)

$debug = nil
$full_scan = nil
opts.each do |opt, arg|
  case opt
    when '--help'
      puts "#{$0} [OPTION]

-h, --help:
   Show help.

-d, --debug
   Debug mode.

-f, --full-scan
   Full scan mode.

"
      exit
    when '--debug'
      $debug = true
    when '--full-scan'
      $full_scan = true
  end
end

#
#
#

def dpp(msg)
  if $debug
    if msg.class == String
      puts msg
    else
      pp msg
    end
  end
end

agent = Mechanize.new
url = "https://forums.aws.amazon.com/ann.jspa?annID=910"
agent.get(url)
cfips = agent.page.at('div#jive-annpage div.jive-body').text.scan(/([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+\/[0-9]+)/)

edges = Hash::new

for cfcidr in cfips do
  cidr4 = NetAddr::CIDR.create(cfcidr[0])
  cnt = 0
  while cnt < cidr4.size do
    tmpip = cidr4.nth(cnt)

    tries = 0
    tmp_name = ""
    begin
      #p "trying " + tmpip
      tmp_name = Resolv.getname tmpip
    rescue Resolv::ResolvError
      tries += 1
      tmpip = cidr4.nth(cnt + 4)
      retry if tries < 2
    end
    if tmp_name != "" && tmp_name =~ /\.r\.cloudfront\.net$/
      #puts tmpip + " : " + tmp_name
      edg = tmp_name.gsub(/^.*\.([a-zA-Z0-9]+)\.r.cloudfront.net$/, '\1')

      if edges[edg] == nil
        edges[edg] = [tmpip + "/24"]
      else
        edges[edg].push tmpip + "/24"
      end

    end
    # I assume they are using the network block partitioning every 256 addresses.( /24 CIDR )
    cnt = cnt + 256
  end
end

uphost_on_the_edges = Hash::new

edges.each{|edge, cidrs|

  dpp edge
  dpp cidrs
  for cidr in cidrs
    if ! uphost_on_the_edges[edge].nil?
      break
    end

    tmpcidr = NetAddr::CIDR.create(cidr)
    tmptargets = *(5..250).sort_by{rand}.values_at(0..9)
    for tmptarget in tmptargets
      tmpip = tmpcidr.nth(tmptarget)
      ping_tcp = Net::Ping::TCP.new(tmpip, 80)
      if ping_tcp.ping?
        uphost_on_the_edges[edge] = tmpip
        dpp "#{tmpip}:80 up"
        break
      else
        dpp "#{tmpip}:80 failed.."
      end
    end
  end
}

pp uphost_on_the_edges
