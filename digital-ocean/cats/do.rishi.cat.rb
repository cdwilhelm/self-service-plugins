name "Base Linux for DigitalOcean"
rs_ca_ver 20131202
short_description "Allows you to launch a machine on DigitalOcean


![logo](http://curvve-curvvemedia.netdna-ssl.com/wp-content/uploads/2013/08/Digital-Ocean-logo-tall-175x100.png)
"

long_description "Allows you to launch a machine on DigitalOcean

![logo](http://curvve-curvvemedia.netdna-ssl.com/wp-content/uploads/2013/08/Digital-Ocean-logo-tall-175x100.png)
"

#########
# Digital Ocean Service
#########
namespace "do" do
  service do
    host "ec2-54-202-222-194.us-west-2.compute.amazonaws.com"        # HTTP endpoint presenting an API defined by self-service to act on resources
    path "/api/do_proxy"                                             # path prefix for all resources, RightScale account_id substituted in for multi-tenancy
    headers do {
      "X-Api-Version" => "1.0"                                       # special headers as needed
    } end
  end
  type "droplet" do                       # defines resource of type "droplet"
    provision "provision_droplet"         # name of RCL definition to use to provision the resource
    delete "delete_droplet"               # name of RCL definition to use to delete the resource
    fields do                             # field of a droplet with rules for validation
      name do                               
        type "string"
        required true
      end
      region do                               
        type "string"
        required true
      end
      size do                               
        type "string"
        required true
      end
      image do                               
        type "number"
        required true
      end
    end
  end
end

# Define the RCL definitions to create and destroy the resource
define provision_droplet(@raw_droplet) return @droplet do
  @droplet = do.droplet.create(droplet: to_object(@raw_droplet)) # Calls .create on the API resource
end
define delete_droplet(@droplet) do
  @droplet.destroy() # Calls .delete on the API resource
end

#########
# Parameters
#########

#########
# Mappings
#########

#########
# Operation
#########
operation "Power Cycle" do
  definition           "do_power_cycle"
  description          "Power cycle the instance"
end

operation "Power Off" do
  definition           "do_power_off"
  description          "Power off the instance before deleting it"
end

#########
# Resources
#########

resource "base_server", type: "do.droplet" do
  name                  "rishi-self-service-drop-01"
  size                  "512mb"
  region                "sfo1"
  image                 5141286
end

#########
# RCL
#########

define do_power_cycle(@base_server) do
  @base_server.powercycle()
end

define do_power_off(@base_server) do
  @base_server.poweroff()
end
