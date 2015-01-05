#
# == Defined resource type: cloudstack::seed_nfs
#
#   This class will add NFS-based secondary storage to a Cloudstack zone and seed it with
#   with system template VMs.
#
# == Parameters
#
# == Sample Usage
#
define cloudstack::seed_nfs inherits cloudstack::params (
  $zonename,
  $cs_sec_storage_nfs_url,
  $hvtype,
) {

  # Variables

  $cs_sec_storage_name = $name
  $mgmt_port           = $::cloudstack::mgmt_port
  $system_tmplt_dl_cmd = '/usr/share/cloudstack-common/scripts/storage/secondary/cloud-install-sys-tmpl'
  $sysvm_url_kvm       = $::cloudstack::params::sysvm_url_kvm
  $sysvm_url_xen       = $::cloudstack::params::sysvm_url_xen
  $ospath              = $::cloudstack::params::ospath
  $hypervisortypes_small     = $::cloudstack::params::hypervisortypes_small

  $zoneid = inline_template("curl \'http://localhost:<% @mgmt_port %>/?command=listZones&name=<% @zonename %>&response=default | xgrep -s \'zone:name/<% @zonename %>/\' | grep \'<id>\' | sed -e \'s/<[^>]*>//g\' | awk \'{print $1}\'")
  $chk_sec_storage_cmd = "curl \'http://localhost:${mgmt_port}/?command=listImageStores&zoneid=${zoneid}&response=default | xgrep -s \'imagestore:zonename/${zonename}/\' | grep \'<id>\' | sed -e \'s/<[^>]*>//g\' | awk \'{print $1}\'"
  $add_sec_storage_cmd = "curl \'http://localhost:${mgmt_port}/?command=addSecondaryStorage&url=nfs://${cs_sec_storage_nfs_url}&zoneid=${zoneid}"

  $secondary_mnt_base = '/mnt/secondary'

  $sysvm_url = $hvtype ? {
    'xenserver' => $sysvm_url_xen,
    'kvm'       => $sysvm_url_kvm,
    default     => $sysvm_url_kvm
  }

  # Validation
  validate_string($zonename)
  validate_string($cs_sec_storage_nfs_url)
  validate_string($hvtype)
  validate_re($hvtype, $hypervisortypes_small)

  # Resources

  include ::cloudstack
  include ::cloudstack::cloudmonkey

  # This will need to move out of here and into common...
  file { $secondary_mnt_base:
    ensure => directory      # FIXME: Need more permissions
  }

    # Need to create (or require) the secondary storage for the zone
  file { "${secondary_mnt_base}/zone_${zonename}":
    ensure => directory      # FIXME: Need more permissions
  }
  mount { "${secondary_mnt_base}/zone_${zonename}":
    ensure => mounted,
    fstype => 'nfs',
    device => $cs_sec_storage_nfs_url
  }
  exec { "cs_add_sec_storage_to_zone__${zonename}":
    command => $add_sec_storage_cmd,
    unless => $chk_sec_storage_cmd,
  }
  exec { "cs_seed_zone__${zonename}":
    command => "${system_tmplt_dl_cmd} -m ${secondary_mnt_base}/zone_${zonename} -u ${sysvm_url} -h ${hvtype} -F ; touch /var/lib/cloud/ssvm",
    # FIXME: Is this a good check?
    unless  => 'test -f /var/lib/cloud/ssvm'  # FIXME:  This resource may take a while to run.
  }

  # Dependencies

  File['/mnt/secondary']
    -> File["/mnt/secondary/${zonename}"]
    -> Mount["/mnt/secondary/${zonename}"]
    -> Exec["cs_seed_zone__${zonename}"]
  Cloudstack::Zone[$zonename]
    -> Exec["cs_add_sec_storage_to_zone__${zonename}"]
  Exec["cs_add_sec_storage_to_zone__${zonename}"]
    -> Exec["cs_seed_zone__${zonename}"]
}
