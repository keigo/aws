aws
===

- cf-edge-location.rb
List edge location IP addresses. Usually, this command takes about 10 minutes to complete.

Sample:
$ ruby cf-edge-location.rb
{"dfw3"=>"xxx.xxx.xxx.xxx",
 "sfo9"=>"xxx.xxx.xxx.xxx",
 "sfo5"=>"xxx.xxx.xxx.xxx",
 ...
 "iad5"=>"xxx.xxx.xxx.xxx"}

Try --debug to see what is going on.

