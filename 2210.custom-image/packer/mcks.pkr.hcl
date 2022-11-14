packer {
  required_plugins {
    amazon = {
      version = ">= 0.0.2"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

source "amazon-ebs" "ubuntu1804" {
  ami_name      = "mcks-custom-image-aws"
  instance_type = "t2.medium"
  region        = "ap-northeast-1" //tokyo
  source_ami_filter {
    filters = {
      name                = "ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"] # Canonical
  }
  ssh_username = "ubuntu"
}

build {
  name    = "mcks-custom-image"
  sources = ["source.amazon-ebs.ubuntu1804"]

  provisioner "file" {
    source      = "./bootstrap.sh"
    destination = "~/bootstrap.sh"
  }

  provisioner "shell" {
    inline = [
      "chmod +x ~/bootstrap.sh",
      "~/bootstrap.sh",
    ]
  }

}