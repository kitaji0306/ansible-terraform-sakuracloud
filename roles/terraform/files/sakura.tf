# genareate ssh key
resource sakuracloud_ssh_key_gen "key" {
  name = "foobar"

  provisioner "local-exec" {
    command = "echo \"${self.private_key}\" > id_rsa; chmod 0600 id_rsa"
  }

  provisioner "local-exec" {
    when    = "destroy"
    command = "rm -f id_rsa"
  }
}

# target zone
provider sakuracloud {
  token  = "****"
  secret = "****"
  zone   = "is1b" # tk1v=Sandbox
}

# archive data
data sakuracloud_archive "centos" {
  filter = {
    name   = "Tags"
    values = ["current-stable", "arch-64bit", "distro-centos"]
  }
}

# disk config
resource "sakuracloud_disk" "disk" {
  name              = "disk01"
  source_archive_id = "${data.sakuracloud_archive.centos.id}"
  password          = "PUT_YOUR_PASSWORD_HERE"
  ssh_key_ids       = ["${sakuracloud_ssh_key_gen.key.id}"]
  disable_pw_auth   = true
}

# server config
resource "sakuracloud_server" "server" {
  name  = "server01"
  disks = ["${sakuracloud_disk.disk.id}"]
  nic   = "shared"
  tags  = ["@group-b", "@boot-cdrom", "@keyboard-us"]

  # provisioning connection
  connection {
    user        = "root"
    host        = "${self.ipaddress}"
    private_key = "${sakuracloud_ssh_key_gen.key.private_key}"
  }

  provisioner "remote-exec" {
    inline = [
      "hostname",
    ] # provision command
  }
}

# show ip address
output "ip_addr" {
    value = "${sakuracloud_server.server.ipaddress}"
}

