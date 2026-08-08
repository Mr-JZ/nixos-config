let
  mr-jz = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINpZ3KLzZdtUF8RCQ3mh6GJ/IATq7d9yIusxU/dgmwxF";
  masterlaptop = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOuFXyHqXQT5eQTn+itnv5VfT1pmPyPwYQngskkBJkFc";
in
{
  "api-keys.age".publicKeys = [
    mr-jz
    masterlaptop
  ];
  "gcloudrc.age".publicKeys = [
    mr-jz
    masterlaptop
  ];
}
