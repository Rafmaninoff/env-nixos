{ config, pkgs, ... }:
{
  services.ananicy = with pkgs; {
    enable = true;
    package = ananicy-cpp;
    rulesProvider = ananicy-rules-cachyos;
  };

}
