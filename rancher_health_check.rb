require 'net/http'
require 'openssl'
require 'rubygems'
require 'json'

class InstanceHealthCheck
	def initialize
		@rancher_uri = URI("#{ENV['RANCHER_URL']}v1/projects/#{ENV['RANCHER_ENV']}/hosts")
		puts @rancher_uri
		@pd_url = URI(ENV['PD_URL'])
		@pd_http = Net::HTTP.new(@pd_url.host, @pd_url.port)
		@pd_http.use_ssl = true
		@pd_request = Net::HTTP::Post.new(@pd_url, 'Content-Type' => 'application/json')

		@active_alerts = Hash.new
		
  	end

  	def rcheck()
  		response = nil
  		Net::HTTP.start(@rancher_uri.host, @rancher_uri.port,
  						:use_ssl => @rancher_uri.scheme == 'https', 
  						:verify_mode => OpenSSL::SSL::VERIFY_NONE) do |http|
  							rancher_request = Net::HTTP::Get.new @rancher_uri.request_uri
  							rancher_request.basic_auth ENV['CATTLE_ACCESS_KEY'], ENV['CATTLE_SECRET_KEY']	
  							response = http.request rancher_request 
  							end 
							body = JSON.parse(response.body)

  						
	  	
	  	#puts body
	  	body['data'].each do |u|
	  		host = u['hostname']
	  		puts host
	  		if u['state'] == 'active'
	  			alert_key = @active_alerts["#{host}"]
	  			if @active_alerts.key?(host)
		  				recovered = "{
							\"service_key\": \"#{ENV['PD_API_KEY']}\",
						  	\"event_type\": \"resolve\",
						  	\"incident_key\": \"#{alert_key}\",
						  	\"description\": \"#{u['hostname']} is not checking into rancher\",
						  	\"client\": \"#{ENV['ENVIRONMENT']}\"
						}"
						puts recovered
						@pd_request.body = recovered
						pd_response = @pd_http.request(@pd_request)
						pd_response = JSON.parse(pd_response.body)
						puts pd_response
						@active_alerts.delete(host)
				end
	  	elsif not @active_alerts.key?(host)
	  		alert = "{
						\"service_key\": \"#{ENV['PD_API_KEY']}\",
					  	\"event_type\": \"trigger\",
					  	\"description\": \"#{u['hostname']} is not checking into rancher\",
					  	\"client\": \"#{ENV['ENVIRONMENT']}\"
					}"
			puts alert
			@pd_request.body = alert
			pd_response = @pd_http.request(@pd_request)
			pd_response = JSON.parse(pd_response.body)
			@active_alerts["#{u['hostname']}"] = pd_response['incident_key']
			puts @active_alerts
		end
	  end
	end
end
def main
	hcheck = InstanceHealthCheck.new
	while true do
		hcheck.rcheck()
		sleep(120)
	end
end
main
