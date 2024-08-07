# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, inputs, ... }:
let
  pkgs-stable = inputs.nixpkgs-stable.legacyPackages.x86_64-linux;
  kmonad = (import ./kmonad.nix) pkgs;
in
{
  imports =
    [
      ./hardware-configuration.nix
      ./ananicy.nix
      ./0t1.nix
      ./gaming.nix
      ./fonts.nix
      ./sudo.nix
      ./sops.nix
      ./ssh.nix
      ./openrgb.nix
      ./blocky.nix
      modules/duckdns.nix
    ];

  # Bootloader.
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot = {
    enable = true;
    configurationLimit = 30;
    netbootxyz = {
      enable = true;
      sortKey = "y-netbootxyz.conf";
    };
    memtest86 = {
      enable = true;
      sortKey = "z-memtest86.conf";
    };
  };

  #why is this not enabled by default yet?
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  services.duckdns = {
    enable = true;
    domains = [ "rafmaninoff" ];
    tokenFile = /run/secrets/duckdns_token;
  };

  nix.optimise = {
    automatic = true;
    dates = [ "00:00:00" ];
  };


  networking.hostName = "nixos-raf"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/Montevideo";

  # Select internationalisation properties.

  i18n = {
    defaultLocale = "en_US.UTF-8";

    extraLocaleSettings = {
      LC_ADDRESS = "es_UY.UTF-8";
      LC_IDENTIFICATION = "es_UY.UTF-8";
      LC_MEASUREMENT = "es_UY.UTF-8";
      LC_MONETARY = "es_UY.UTF-8";
      LC_NAME = "es_UY.UTF-8";
      LC_NUMERIC = "es_UY.UTF-8";
      LC_PAPER = "es_UY.UTF-8";
      LC_TELEPHONE = "es_UY.UTF-8";
      LC_TIME = "es_UY.UTF-8";
    };

    inputMethod = {
      type = "fcitx5";
      enable = true;
      fcitx5 = {
        waylandFrontend = true;
        addons = with pkgs; [
          fcitx5-mozc
          fcitx5-material-color
        ];
      };
    };
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  services.displayManager.sddm = { enable = true; wayland.enable = true; };
  services.desktopManager.plasma6.enable = true;

  programs.hyprland = {
    enable = true;
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
    options = "compose:102,caps:hyper,lv3:ralt_switch,nbsp:zwnj2nb3zwj4";
  };

  # Enable CUPS to print documents.
  services.printing.enable = false;

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  services.blueman.enable = true;

  services.flatpak.enable = true;

  # Enable sound with pipewire.
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.raf = {
    isNormalUser = true;
    description = "raf";
    shell = pkgs.zsh;
    extraGroups = [ "networkmanager" "wheel" "input" "uinput" "adbusers" ];
    packages = with pkgs; [
      firefox
      microsoft-edge
      #  thunderbird
    ];
  };

  users.groups = { uinput = { }; };

  services.udev.extraRules =
    ''
      # KMonad user access to /dev/uinput
      KERNEL=="uinput", MODE="0660", GROUP="uinput", OPTIONS+="static_node=uinput"
    '';

  programs.adb.enable = true;

  virtualisation = {
    spiceUSBRedirection.enable = true;
    podman = {
      enable = false;

      # Create a `docker` alias for podman, to use it as a drop-in replacement
      dockerCompat = true;

      # Required for containers under podman-compose to be able to talk to each other.
      defaultNetwork.settings.dns_enabled = true;
    };
  };

  #use lix as nix impl, mostly so cached error is an error of the past.
  nix.package = pkgs.lix;

  # Allow unfree packages
  nixpkgs.config = {
    allowUnfree = true;
    allowUnfreePredicate = (_: true);
  };

  xdg.portal.enable = true;

  services.input-remapper = {
    enable = true;
  };

  boot.binfmt.registrations.appimage = {
    wrapInterpreterInShell = false;
    interpreter = "${pkgs.appimage-run}/bin/appimage-run";
    recognitionType = "magic";
    offset = 0;
    mask = ''\xff\xff\xff\xff\x00\x00\x00\x00\xff\xff\xff'';
    magicOrExtension = ''\x7fELF....AI\x02'';
  };

  programs.nh = {
    enable = true;
    clean = {
      enable = true;
      extraArgs = "--keep-since 15d --keep 5";
    };
    flake = "/home/raf/env-nixos";
  };

  environment.systemPackages = (with pkgs; [
    sops
    vim
    scx
    age
    gnome-disk-utility
    deluge
    wget
    flameshot
    clac
    vlc
    appimage-run
    piper
    libreoffice-qt
    hunspell
    hunspellDicts.es_ES
    hunspellDicts.en_GB-ise
    kmonad
    signal-desktop
    filelight
    arrpc
    vesktop
    telegram-desktop
    zapzap
    nchat
    # firedragon
    swayidle
    scrcpy
  ])
  ++
  (with pkgs-stable; [
    quickemu
    floorp
    # FIXME does this still need to be on stable?
    btrfs-assistant
  ]);

  systemd.user.services = {
    arrpc = {
      partOf = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      wantedBy = [ "graphical-session.target" ];

      description = "Discord rich presence for non-default clients";
      serviceConfig = {
        ExecStart = "${lib.getExe pkgs.arrpc}";
        Restart = "always";
      };
    };
  };

  services.mullvad-vpn = {
    enable = true;
    enableExcludeWrapper = true;
  };

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [ ];
  };

  services.ratbagd.enable = true;

  programs.zsh.enable = true;
  programs.kdeconnect.enable = true;

  programs.corectrl = {
    enable = true;
    gpuOverclock = {
      enable = true;
      ppfeaturemask = "0xffffffff";
    };
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  programs.mtr.enable = true;
  programs.gnupg.dirmngr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall = {
    enable = true;
  };


  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?

}
