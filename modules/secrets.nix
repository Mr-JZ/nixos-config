{ username, ... }:

{
  age.secrets = {
    api-keys = {
      file = ../secrets/api-keys.age;
      owner = username;
      group = "users";
      mode = "0400";
    };
    gcloudrc = {
      file = ../secrets/gcloudrc.age;
      owner = username;
      group = "users";
      mode = "0400";
    };
  };
}
