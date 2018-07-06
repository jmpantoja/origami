require 'getoptlong'
require 'yaml'

# Return an array with parsed cli arguments
def parse_args(extra)
    args = {};

    args['playbook']='playbook'
    args['env']='dev'

    opts = GetoptLong.new(
      [ '--env', GetoptLong::REQUIRED_ARGUMENT ],
      [ '--provision', GetoptLong::NO_ARGUMENT ],
      [ '--no-provision', GetoptLong::NO_ARGUMENT ],
      [ '--force', GetoptLong::NO_ARGUMENT ],
      [ '--deploy', GetoptLong::NO_ARGUMENT ],
      [ '--rollback', GetoptLong::NO_ARGUMENT ],
      [ '--tags', GetoptLong::REQUIRED_ARGUMENT ]
    )

    opts.each do |opt, arg|
      case opt
        when '--env'
          args['env']=arg
        when '--tags'
          args['tags']=arg
        when '--deploy'
          args['playbook']='deploy'
        when '--rollback'
          args['playbook']='rollback'
      end
    end

    extra.each do |key, value|
        args["#{key}"] = value
    end

    args
end

# Return the combined configuration content all files provided.
def load_config(files, args)
  vconfig = {}
  files.each do |config_file|
    if File.exist?(config_file)
      optional_config = YAML.load_file(config_file)
      vconfig.merge!(optional_config) if optional_config
    else
      raise_message "Configuration file not found! Expected in #{config_file}"
    end
  end
  vconfig.merge!(args) if args
  resolve_jinja_variables(vconfig)

end


# Recursively walk an tree and run provided block on each value found.
def walk(obj, &function)
  if obj.is_a?(Array)
    obj.map { |value| walk(value, &function) }
  elsif obj.is_a?(Hash)
    obj.each_pair { |key, value| obj[key] = walk(value, &function) }
  else
    obj = yield(obj)
  end
end

# Resolve jinja variables in hash.
def resolve_jinja_variables(vconfig)
  walk(vconfig) do |value|
    while value.is_a?(String) && value.match(/{{ .* }}/)
      value = value.gsub(/{{ (.*?) }}/) { vconfig[Regexp.last_match(1)] }
    end
    value
  end
end

#show an error message
def raise_message(msg)
  raise Vagrant::Errors::VagrantError.new, msg
end

#install the vagrant plugins
def ensure_plugins(plugins)
  logger = Vagrant::UI::Colored.new
  installed = false

  plugins.each do |plugin|
    plugin_name = plugin['name']
    manager = Vagrant::Plugin::Manager.instance

    next if manager.installed_plugins.key?(plugin_name)

    logger.warn("Installing plugin #{plugin_name}")

    manager.install_plugin(
      plugin_name,
      sources: plugin.fetch('source', %w[https://rubygems.org/ https://gems.hashicorp.com/]),
      version: plugin['version']
    )

    installed = true
  end

  return unless installed

  logger.warn('`vagrant up` must be re-run now that plugins are installed')
  exit
end


# Return a list of all virtualhost server names and aliases from a config hash.
def get_vhost_aliases(settings, vconfig)

    aliases = []
    is_frontend = settings['frontend'] ||= false

    if !is_frontend
        return aliases
    end


    vhosts = vconfig["nginx_vhosts"] ||= []
    vhosts.each do |host|
        aliases.push(host['server_name'])
        aliases.concat(host['server_name_redirect'].split) if host['server_name_redirect']
    end

    # Remove wildcard subdomains.
    aliases.delete_if { |vhost| vhost.include?('*') }

    aliases
end


def get_ansible_groups(vconfig)
  ansible_groups = {}

  machines = vconfig["machines"] ||= []

  machines.each do |name, machine|

    name = machine['name'] ||= name
    groups = machine['groups'] ||= []

    groups.each do |group|
        ansible_groups[group] = ansible_groups[group] ||= []
        ansible_groups[group].push(name)
    end
  end

  ansible_groups
end

def get_extra_vars(vconfig, settings)
    filtered = settings.except(
        'name',
        'hostname',
        'ip',
        'networks',
        'groups',
        'provider',
        'box',
        'memory',
        'cpus',
        'natdnshostresolver',
        'gui',
        'folders',
        'ports',
        'token',
        'image',
        'size',
        'region',
        'default_ssh_port',
        'update_parallels_tools',
        'authorize',
        'keys',
        'copy'
        )

    extra_vars = vconfig.merge(filtered)
    extra_vars
end
