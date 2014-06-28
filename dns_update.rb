require 'net/http'
require 'YAML'
require 'AWS'

config = YAML.load_file('config.yml')

ip_address = Net::HTTP.get('ipecho.net', '/plain')

AWS.config({
    access_key_id: config["AWS"]["access_key_id"],
    secret_access_key: config["AWS"]["secret_access_key"]
          });

resp = AWS::Route53.new.client.list_hosted_zones

config["Zone"].each do |targetZone, records|
  puts "Working on zone #{targetZone}"
  found = resp[:hosted_zones].find { |zone| zone[:name] == targetZone }
  zoneRouteSet = AWS::Route53::HostedZone.new(found[:id]).rrsets
  records.each do |value|
    target = "#{value}.#{targetZone}"
    puts "Working on record #{target}"
    record = zoneRouteSet[target, 'A']
    current = record.resource_records[0][:value]
    unless current == ip_address
      puts "Changing #{current} to ${ip_address} for #{target}"
      target.resource_records = [ { value: ip_address } ]
      target.update
    end
  end
end