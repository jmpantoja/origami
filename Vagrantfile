# -*- mode: ruby -*-
# vi: set ft=ruby :

# directories
project_dir = File.dirname(File.expand_path(__FILE__))
origami_dir = "#{project_dir}/.origami"

require_relative "#{origami_dir}/lib/vagrant.rb"
require_relative "#{origami_dir}/lib/machine.rb"

args = parse_args({
    project_dir: project_dir,
    origami_dir: origami_dir
});


#config
vconfig = load_config([
  "#{project_dir}/config.yml",
  "#{project_dir}/#{args['env']}.config.yml"
], args)

# Verify Vagrant version requirement.
Vagrant.require_version ">= #{vconfig['vagrant_version_min']}"
ensure_plugins(vconfig['vagrant_plugins'])

Vagrant.configure("2") do |config|

    # SSH options.
    config.ssh.insert_key = false
    config.ssh.forward_agent = true

    # Vguest
    config.vbguest.auto_update = false

    # HostManager
    config.hostmanager.enabled = false
    config.hostmanager.manage_host = false
    config.hostmanager.manage_guest = true
    config.hostmanager.ignore_private_ip = false
    config.hostmanager.include_offline = true

    vconfig['machines'].each do |name, settings|
        settings['name'] = settings['name'] ||= name
        primary = settings['primary'] ||= false
        autostart  = settings['autostart'] ||= true

        config.vm.define settings['name'], primary: primary, autostart: autostart do |node|
            Machine.configure(node, settings, vconfig)
            Machine.provision(node, settings, vconfig)

            node.hostmanager.aliases = get_vhost_aliases(settings, vconfig)
        end
    end

    config.vm.provision "hostmanager"

end
