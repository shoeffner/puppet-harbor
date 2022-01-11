# frozen_string_literal: true
require 'puppet_x/walkamongus/harbor/client'

Puppet::Type.type(:harbor_ldap_user_group).provide(:swagger) do
  mk_resource_methods
  desc 'Swagger API implementation for harbor LDAP user group'

  def self.instances
    api_instance = self.do_login
    groups = self.get_usergroups
    if groups.nil?
      []
    else
      groups.map do |group|
        new(
          ensure:        :present,
          group_name:    group.group_name,
          ldap_group_dn: group.ldap_group_dn,
          provider:      :swagger,
        )
      end
    end
  end

  def self.get_usergroups(opts={page_size: 20})
    self.validate_page_size(opts[:page_size])

    api_instance = self.do_login
    api_client = api_instance[:legacy_client].api_client

    header_params = {
      'Accept': api_client.select_header_accept(['application/json', 'text/plain']),
      'Content-Type': api_client.select_header_content_type(['application/json'])
    }

    groups = []
    begin
      page = 1
      loop do
        group_page, status, headers = api_client.call_api(:GET, '/usergroups',
          :header_params => header_params,
          :query_params => {:page => page}.merge(opts),
          :form_params => {},
          :body => nil,
          :auth_names => ['basicAuth'],
          :return_type => 'Array<Harbor2LegacyClient::UserGroup>'
        )
        groups.concat(group_page)
        break if headers['Link'].nil? || !headers['Link'].contains('rel="next"')
        page += 1
      end
    rescue Harbor2LegacyClient::ApiError => e
      fail RuntimeError.new("[puppet-harbor] Failed querying /usergroups endpoint: #{e}")
    end
    groups
  end

  def self.validate_page_size(page_size)
    if !page_size.nil? && (page_size < 1 || page_size > 100)
      fail RuntimeError.new("[puppet-harbor] page_size for get_usergroups must be between 1 and 100 (inclusively). Was #{opts[:page_size]}.")
    end
  end

  def self.do_login
     PuppetX::Walkamongus::Harbor::Client.do_login
  end

  def self.prefetch(resources)
    instances.each do |int|
      if (resource = resources[int.ldap_group_dn])
        resource.provider = int
      end
    end
  end

  def exists?
    group = get_group_with_ldap_dn(resource[:ldap_group_dn])
    !group.nil?
  end

  def get_group_with_ldap_dn(dn)
    groups = get_groups_containing_ldap_dn(dn)
    groups
  end

  def get_groups_containing_ldap_dn(dn)
    opts = { ldap_group_dn: dn }
    get_groups_with_opts(opts)
  end

  def get_groups_with_opts(opts)
    api_instance = self.class.do_login
    begin
      groups = self.class.get_usergroups(opts)
      groups.nil? ? [] : groups
    rescue Harbor2LegacyClient::ApiError => e
      puts "Exception when calling ProductsApi->usergroups_get: #{e}"
    rescue Harbor1Client::ApiError => e
      puts "Exception when calling ProductsApi->usergroups_get: #{e}"
    end
  end

  def create
    api_instance = self.class.do_login
    if api_instance[:api_version] == 2
      group = Harbor2LegacyClient::UserGroup.new(
        group_name: resource[:group_name],
        group_type: 1,
        ldap_group_dn: resource[:ldap_group_dn],
      )
    else
      group = Harbor1Client::UserGroup.new(
        group_name: resource[:group_name],
        group_type: 1,
        ldap_group_dn: resource[:ldap_group_dn],
      )
    end
    begin
      api_instance[:legacy_client].usergroups_post(opts = {usergroup: group})
    rescue Harbor2LegacyClient::ApiError => e
      puts "Exception when calling ProductsApi->usergroups_post: #{e}"
    rescue Harbor1Client::ApiError => e
      puts "Exception when calling ProductsApi->usergroups_post: #{e}"
    end
  end

  def group_name=(_value)
    api_instance = self.class.do_login
    if api_instance[:api_version] == 2
      group = Harbor2LegacyClient::UserGroup.new(
        group_name: _value,
        group_type: 1,
        ldap_group_dn: resource[:ldap_group_dn],
      )
    else
      group = Harbor1Client::UserGroup.new(
        group_name: _value,
        group_type: 1,
        ldap_group_dn: resource[:ldap_group_dn],
      )
    end
    id = get_id_of_group_with_ldap_dn(resource[:ldap_group_dn])
    update_group_with_id(id, group)
  end

  def get_id_of_group_with_ldap_dn(dn)
    group = get_group_with_ldap_dn(dn)
    group.id
  end

  def update_group_with_id(id, group)
    api_instance = self.class.do_login
    begin
      api_instance[:legacy_client].usergroups_group_id_put(id, opts = {usergroup: group})
    rescue Harbor2LegacyClient::ApiError => e
      puts "Exception when calling ProductsApi->usergroups_group_id_put: #{e}"
    rescue Harbor1Client::ApiError => e
      puts "Exception when calling ProductsApi->usergroups_group_id_put: #{e}"
    end
  end

  def destroy
    group = get_group_with_ldap_dn(resource[:ldap_group_dn])
    delete_group_with_id(group.id)
  end

  def delete_group_with_id(id)
    api_instance = self.class.do_login
    begin
      api_instance[:legacy_client].usergroups_group_id_delete(id)
    rescue Harbor2LegacyClient::ApiError => e
      puts "Exception when calling ProductsApi->usergroups_group_id_delete: #{e}"
    rescue Harbor1Client::ApiError => e
      puts "Exception when calling ProductsApi->usergroups_group_id_delete: #{e}"
    end
  end
end
