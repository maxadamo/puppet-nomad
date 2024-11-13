require 'json'
require 'tempfile'

Puppet::Type.type(:nomad_key_value).provide(:cli) do
  desc 'Provider to manage Nomad variables using `nomad var put`.'

  def nomad_command
    resource[:binary_path]
  end

  def build_command_args
    raise Puppet::Error, "Nomad binary at #{resource[:binary_path]} is not executable or not found." unless File.executable?(resource[:binary_path])

    args = []
    args << "-token=#{resource[:token]}" unless resource[:token].to_s.empty?
    args << "-address=#{resource[:address]}"
    args << "-region=#{resource[:region]}"
    args << "-namespace=#{resource[:namespace]}" unless resource[:namespace].to_s.empty?
    args << "-tls-server-name=#{resource[:tls_server_name]}" unless resource[:tls_server_name].to_s.empty?
    args << '-tls-skip-verify' if resource[:skip_verify] == true
    args << "-client-key=#{resource[:client_key]}" unless resource[:client_key].to_s.empty?
    args << "-client-cert=#{resource[:client_cert]}" unless resource[:client_cert].to_s.empty?
    args << "-ca-cert=#{resource[:ca_cert]}" unless resource[:ca_cert].to_s.empty?
    args << "-ca-path=#{resource[:ca_path]}" unless resource[:ca_path].to_s.empty?
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
    puts "Existing items: #{@existing_items}"
    puts "Value set on Puppet: #{resource[:value]}"
    @existing_items == resource[:value]
  end

  def create
    puts 'create'
    run_nomad_command(resource[:value])
    puts 'end of create'
  end

  def update
    puts 'update'
    run_nomad_command(resource[:value], @modify_index)
    puts 'end of update'
  end

  def destroy
    puts 'destroy'
    command = [nomad_command, 'var', 'delete'] + build_command_args + [resource[:name]]
    execute(command)
    puts 'end of destroy'
  end

  private

  def run_nomad_command(value, modify_index = nil)
    json_value = { 'Items' => value }.to_json
    command = [nomad_command, 'var', 'put', '-in', 'json'] + build_command_args
    command += ['-check-index', modify_index.to_s] if modify_index
    #puts "JSON from Puppet manifest #{json_value}"
    #puts command.join(' ')
    #puts resource[:name]

    Tempfile.open('nomad_var') do |tempfile|
      tempfile.write(json_value)
      tempfile.flush
      #puts tempfile.path
      execute(command + [resource[:name], '-'], stdinfile: tempfile.path)
    end
    puts 'end of run_nomad_command'
  end
end
