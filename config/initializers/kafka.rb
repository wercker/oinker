require 'resolv'
require 'kafka'

Resolv::DNS.open do |dns|
  ress =
    dns.getresources("_broker-0._tcp.kafka.mesos", Resolv::DNS::Resource::IN::SRV) +
    dns.getresources("_broker-2._tcp.kafka.mesos", Resolv::DNS::Resource::IN::SRV) +
    dns.getresources("_broker-1._tcp.kafka.mesos", Resolv::DNS::Resource::IN::SRV)

  if ress.first
    opts = {
      topic: 'requests',
      host: ress.first.target.to_s,
      port: ress.first.port
    }
    Rails.logger.info("Connecting to Kafka at #{opts.inspect}")
    KAFKA = Kafka::Producer.new(opts)
  else
    Rails.logger.warn("Could not find Kafka brokers")
  end
end
