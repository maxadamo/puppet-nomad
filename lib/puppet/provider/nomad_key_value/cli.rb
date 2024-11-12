require 'json'

Puppet::Type.type(:nomad_key_value).provide(:cli) do
  desc 'Provider to manage Nomad variables using `nomad var put`.'

  def nomad_command
    resource[:binary_path]
  end

  def build_command_args
    unless File.executable?(resource[:binary_path])
      raise Puppet::Error, "Nomad binary at #{resource[:binary_path]} is not executable or not found."
    end

    args = []
    args << "-token=#{resource[:token]}" unless resource[:token].nil? || resource[:token].empty?
    args << "-address=#{resource[:address]}"
    args << "-datacenter=#{resource[:datacenter]}" unless resource[:datacenter].nil? || resource[:datacenter].empty?
    args << "-region=#{resource[:region]}"
    args << "-namespace=#{resource[:namespace]}" unless resource[:namespace].nil? || resource[:namespace].empty?
    args << "-tls-server-name=#{resource[:tls_server_name]}" unless resource[:tls_server_name].nil? || resource[:tls_server_name].empty?
    args << '-tls-skip-verify' if resource[:skip_verify] == true
    args << "-client-key=#{resource[:client_key]}" unless resource[:client_key].nil? || resource[:client_key].empty?
    args << "-client-cert=#{resource[:client_cert]}" unless resource[:client_cert].nil? || resource[:client_cert].empty?
    args << "-ca-cert=#{resource[:ca_cert]}" unless resource[:ca_cert].nil? || resource[:ca_cert].empty?
    args << "-ca-path=#{resource[:ca_path]}" unless resource[:ca_path].nil? || resource[:ca_path].empty?
    args
  end

  def fetch_existing
    command = [nomad_command, 'var', 'get', '-out', 'json'] + build_command_args + [resource[:name]]
    output = execute(command, failonfail: false)
    JSON.parse(output)
  rescue JSON::ParserError, Puppet::ExecutionFailure
    nil
  end

  def exists?
    result = fetch_existing
    return false if result.nil?

    @modify_index = result['ModifyIndex']
    @existing_items = result['Items']

    @existing_items == resource[:value] # Return true if Items matches the desired value
  end

  def create
    json_value = { 'Items' => resource[:value] }.to_json
    command = [nomad_command, 'var', 'put', '-in', 'json'] + build_command_args

    if @existing_items && @existing_items != resource[:value]
      # Key exists but has different values; use ModifyIndex for an update
      command += ['-check-index', @modify_index.to_s]
    end

    command += [resource[:name], '-']
    Tempfile.open('nomad_var') do |tempfile|
      tempfile.write(json_value)
      tempfile.flush

      execute(command, stdinfile: tempfile.path)
    end
  end

  def destroy
    command = [nomad_command, 'var', 'delete'] + build_command_args + [resource[:name]]
    execute(command)
  end
end
