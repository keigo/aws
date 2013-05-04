# -*- encoding: utf-8 -*-
#
require 'rubygems'
require 'netaddr'
require 'pp'
require 'mechanize'
require 'resolv'

agent = Mechanize.new
url = "https://forums.aws.amazon.com/ann.jspa?annID=910"
agent.get(url)
cfips = agent.page.at('div#jive-annpage div.jive-body').text.scan(/([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+\/[0-9]+)/)

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
      puts tmpip + " : " + tmp_name
    end
    cnt = cnt + 256
  end
end

