resource "aws_key_pair" "key" { # Utilizando o recurso de chave
  key_name   = "aws-provisioner-key" #Nome da chave
  public_key = file("./aws-provisioner-key.pub") #função que chama a chave pública
}

resource "aws_instance" "vm" { #Criando recurso de instância EC2
  ami = "ami-0b0dcb5067f052a63" #Ami utilizada

  instance_type               = "t2.micro" #Tipo da instância
  key_name                    = aws_key_pair.key.key_name #Nome da chave de acesso
  subnet_id                   = data.terraform_remote_state.vpc.outputs.subnet_id #Id da subnet passado via date no remote state da vpc
  vpc_security_group_ids      = [data.terraform_remote_state.vpc.outputs.security_group_id] #Id do security group passado via date no remote state da vpc
  associate_public_ip_address = true #Endereço de IP

  provisioner "local-exec" { #Provisioner local como local-exec
    command = "echo ${self.public_ip} >> public_ip.txt" #O comando Echo cria um arquivo chamado public_ip.txt e armazena as informações de IP público da VM
  }

  provisioner "file" { #Provisioner file
    content     = "public_ip: ${self.public_ip}" #O provisioner file utiliza o recurso de public_ip e faz um envio remoto para o diretório /tmp no arquivo public_ip.txt
    destination = "/tmp/public_ip.txt" #arquivo de destino da vm
  }

  provisioner "file" {  #Provisioner file
    source      = "./teste.txt" #Armazena informações de IP público no arqiovo local teste.txt
    destination = "/tmp/exemplo.txt" #Guarda a informação no diretório /tmp do arquivo exemplo.txt remotamente na vm de destino 
  }

  connection { #bloco de connection para conexões remotas
    type        = "ssh"  #utiliza o protocolo ssh na porta 22 para acesso remoto na vm criada
    user        = "ec2-user" #usuário ec2-user
    private_key = file("./aws-provisioner-key") #Utiliza a chave privada para acesso na vm
    host        = self.public_ip #Ip público do host de destino

  }

  provisioner "remote-exec" { #Provisioner para acesso remoto
    inline = [
      "echo ami: ${self.ami} >> /tmp/ami.txt", #Cria o arquivo ami.txt e armazena informações da ami no diretório /tmp/ami.txt
      "echo private_ip: ${self.private_ip} >> /tmp/private_ip.txt", #Guarda as informações de ip privao no arquivo prvate_ip.txt no /tmp remoto

    ]

  }

  tags = {
    "Name" = "vm-terraform" #nome da vm
  }
}
