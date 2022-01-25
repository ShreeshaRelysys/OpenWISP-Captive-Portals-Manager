# This file is part of the OpenWISP Captive Portal Manager
#
# Copyright (C) 2012 OpenWISP.org
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

require 'ipaddr'
require 'singleton'

module OsUtils

  # Test to see if a string contains a valid interface name
  def is_interface_name?(interface_name)
    not_implemented
    true
  end

  # Test to see if the passed parameter is a valid interface name
  def is_port?(port)
    if port.class == Fixnum
      (0..65535).include?(port.to_i)
    elsif port.class == String
      port =~ /\A\d+\Z/ and (0..65535).include?(port.to_i)
    else
      false
    end
  end

  # Test to see if the passed parameter is a valid ipv4 address
  def is_ipv4_address?(address)
    IPAddr.new(address).ipv4?
  end

  # Test to see if the passed parameter is a valid ipv6 address
  def is_ipv6_address?(address)
    IPAddr.new(address).ipv6?
  end

  # Test to see if the passed parameter is a valid mac address
  def is_mac_address?(address)
    (address =~ /\A([0-9a-f]{1,2}:){5}[0-9a-f]{1,2}\Z/i) != nil
  end

  # Returns the client mac address associated with the passed ipv4/v6 address
  def get_host_mac_address(address)
    not_implemented
    "00:00:00:00:00:00"
  end

  # Returns the interface that will be used to reach the passed ip address
  def get_interface(address)
    not_implemented
    "null"
  end

  # Returns the first ipv4 address assigned to the passed interface name
  def get_interface_ipv4_address(interface)
    not_implemented
    "127.0.0.1"
  end

  # Returns the first non-link-local ipv6 address assigned to the passed interface name
  def get_interface_ipv6_address(interface)
    not_implemented
    "::1"
  end

  def os_type
    ost = %x[uname -s]
    ost.chomp.downcase
  end

  module_function :os_type

end

class OsCaptivePortal
  include OsUtils

  DNS_PORT = 53
  DHCP_SRC_PORT = 68
  DHCP_DST_PORT = 67

  private

  def not_implemented
    puts "[WARNING] Missing (not implemented) code @ '#{caller.first}'"
  end

  public

  # Adds a new captive portal
  def start
    not_implemented
  end

  # Removes a captive portal
  # cp_interface is the name of the interface directly connected the clients
  def stop
    not_implemented
  end

  attr_reader :cp_interface, :wan_interface, :local_http_port, :local_https_port

  # Constructor
  #  * cp_interface is the name of the interface directly connected the clients.
  #  * wan_interface is the interface the clients will be allowed after the authentication
  #  * local_http_port is the local port to witch client will be redirected to when they try to use the http protocol
  #  * local_https_port is the local port used for authentication
  def initialize(cp_interface, wan_interface, local_http_port, local_https_port, options = {})
    raise("[BUG] Invalid CP Interface") unless is_interface_name?(cp_interface)
    raise("[BUG] Invalid WAN Interface") unless is_interface_name?(wan_interface)
    raise("[BUG] Invalid Local HTTP Port") unless is_port?(local_http_port)
    raise("[BUG] Invalid Local HTTPS Port") unless is_port?(local_https_port)

    @cp_interface = cp_interface
    @wan_interface = wan_interface
    @local_http_port = local_http_port
    @local_https_port = local_https_port
    @total_upload_bandwidth = options[:total_upload_bandwidth]
    @total_download_bandwidth = options[:total_download_bandwidth]
    @default_upload_bandwidth = options[:default_upload_bandwidth]
    @default_download_bandwidth = options[:default_download_bandwidth]

  end

  # Add an exception to firewall rules
  def add_allowed_traffic(options = {})
    not_implemented
  end

  # Removes an exception from firewall rules
  def remove_allowed_traffic(options = {})
    not_implemented
  end

  # Allows a client through the captive portal
  def add_user(client_address, client_mac_address, options = {})
    not_implemented
  end

  # Removes a client
  def remove_user(client_address, client_mac_address, options = {})
    not_implemented
  end

  # Returns uploaded and downloaded bytes (respectively) for a given client
  def get_user_bytes_counters(client_address)
    not_implemented
    [0,0]
  end

  # Returns uploaded and downloaded packets (respectively) for a given client
  def get_user_packets_counters(client_address)
    not_implemented
    [0,0]
  end

end

class OsControl
  include Singleton

  private

  def not_implemented
    puts "[WARNING] virtual method not implemented: '#{caller.first}'"
  end

  public

  # Initializes captive portal firewalling infrastructure
  def start
    not_implemented
  end

  # Finalize captive portal firewalling infrastructure
  def stop
    not_implemented
  end

  def initialize
    @captive_portals = Hash.new
  end

  def get_captive_portal(cp_interface)
    @captive_portals[cp_interface]
  end

  def add_captive_portal(cp_interface, wan_interface, local_http_port, local_https_port, options = {})
    raise("[BUG] Captive portal for #{cp_interface} already exists!") unless @captive_portals[cp_interface].nil?

    @captive_portals[cp_interface] = OsCaptivePortal.new(
        cp_interface,
        wan_interface,
        local_http_port,
        local_https_port,
        options
    )
    @captive_portals[cp_interface].start
  end

  def remove_captive_portal(cp_interface)
    raise("[BUG] Captive portal for #{cp_interface} doesn't exists!") unless @captive_portals[cp_interface]

    @captive_portals[cp_interface].stop
    @captive_portals.delete(cp_interface)
  end

  def OsControl.get_os_control
    os = OsUtils.os_type
    begin
      #noinspection RubyResolve
      require File.join(Rails.root.to_s, "lib", "os_captive_portals", "#{os}_captive_portal")
      puts "[INFO] Using #{os} Captive Portal Implementation"
    rescue LoadError
      puts "[WARNING] Using Abstract Captive Portal Implementation (#{os} needed)"
    end
  ensure
    return OsControl.instance
  end

end
