# -*- encoding: utf-8 -*-
#
require 'rubygems'
require 'netaddr'
require 'pp'
require 'mechanize'
require 'resolv'
require 'net/ping'

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

      #tmpip = cidr4.nth(cnt + 10)
      #ping_tcp = Net::Ping::TCP.new(tmpip, 80)
      #puts "#{tmpip}:80\t]" if ping_tcp.ping?
    end
    cnt = cnt + 256
  end
end

pp edges
