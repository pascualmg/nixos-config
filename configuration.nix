{ config, pkgs, ... }: {
  imports =
    [ ./hardware-configuration.nix
      <home-manager/nixos>
    ];

  # Permitir paquetes unfree (necesario para NVIDIA)
  nixpkgs.config.allowUnfree = true;

  # Configuración de Hardware y NVIDIA
  hardware = {
    enableAllFirmware = true;
    opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
    };
    nvidia = {
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      modesetting.enable = true;
      powerManagement.enable = false;  # Desactivado por seguridad inicialmente
      open = false;
      nvidiaSettings = true;
    };
    pulseaudio = {
      enable = true;
      support32Bit = true;
      package = pkgs.pulseaudioFull;
      extraConfig = ''
        load-module module-alsa-sink device=hw:0,0
        load-module module-alsa-source device=hw:0,0
      '';
    };
  };

  # Variables de entorno básicas para NVIDIA
  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "nvidia";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
  };

  # Bootloader
  boot = {
    loader = {
      grub = {
        enable = true;
        device = "/dev/sdc";
        useOSProber = true;
        efiSupport = false;
      };
    };
    kernel.sysctl = {
      "fs.inotify.max_user_watches" = 524288;
      "vm.max_map_count" = 262144;
    };
  };

  # Networking
  networking = {
    hostName = "soxin";
    networkmanager.enable = true;
    firewall = {
      enable = false;
      allowedTCPPorts = [ 80 443 ];
    };
  };

  # Timezone y locale
  time.timeZone = "Europe/Madrid";
  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "es_ES.UTF-8";
      LC_IDENTIFICATION = "es_ES.UTF-8";
      LC_MEASUREMENT = "es_ES.UTF-8";
      LC_MONETARY = "es_ES.UTF-8";
      LC_NAME = "es_ES.UTF-8";
      LC_NUMERIC = "es_ES.UTF-8";
      LC_PAPER = "es_ES.UTF-8";
      LC_TELEPHONE = "es_ES.UTF-8";
      LC_TIME = "es_ES.UTF-8";
    };
  };

  # Audio
  sound.enable = true;

  # Usuario
  users.users.passh = {
    isNormalUser = true;
    description = "passh";
    extraGroups = [ "wheel" "networkmanager" "audio" "video" "docker" ];
    shell = pkgs.bash;
  };

  # Servicios
  services = {
    # X11 y XMonad con soporte NVIDIA básico
    xserver = {
      enable = true;
      videoDrivers = [ "nvidia" ];

      xkb = {
        layout = "es,us";
        variant = "";
      };

      windowManager.xmonad = {
        enable = true;
        enableContribAndExtras = true;
        config = pkgs.writeText "xmonad.hs" (builtins.readFile "/home/passh/.config/xmonad/xmonad.hs");
      };

      desktopManager.xfce.enable = true;

      displayManager = {
        setupCommands = ''
          ${pkgs.xorg.xrandr}/bin/xrandr --output DP-0 --mode 5120x1440 --rate 60 --primary
        '';
      };
    };

    displayManager = {
      defaultSession = "none+xmonad";
    };

    # Compositor con config básica
    picom = {
      enable = true;
      settings = {
        backend = "xrender";  # Más seguro que glx inicialmente
        vsync = true;
        shadow = false;
        inactive-opacity = 1.0;
        active-opacity = 1.0;
        frame-opacity = 1.0;
      };
    };

    # SSH
    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
      };
    };

    # Reglas udev para los dispositivos USB
    udev.extraRules = ''
      # USB Hub
      SUBSYSTEM=="usb", ATTR{idVendor}=="05e3", ATTR{idProduct}=="0626", GROUP="users", MODE="0666"
      # RØDE NT-USB Mini
      SUBSYSTEM=="usb", ATTR{idVendor}=="19f7", ATTR{idProduct}=="0015", GROUP="audio", MODE="0666"
    '';
  };

  # Docker
  virtualisation.docker.enable = true;

  # Paquetes del sistema
  environment.systemPackages = with pkgs; [
    # Basics
    wget
    git
    curl
    vim
    ripgrep
    fd
    tree
    unzip
    zip

    # NVIDIA Tools
    nvidia-vaapi-driver
    nvtop
    vulkan-tools
    glxinfo

    # XMonad y relacionados
    xmonad-with-packages
    xmobar
    trayer
    dmenu
    nitrogen
    picom
    alacritty
    xscreensaver
    xfce.xfce4-clipman-plugin
    flameshot

    # Utilidades del sistema
    alttab
    xorg.setxkbmap
    xorg.xmodmap
    xorg.xinput
    xorg.xset
    dunst
    libnotify
    pciutils
    usbutils
    htop
    neofetch

    # Doom Emacs y dependencias
    emacs
    cmake
    gnumake
    gnutls
    libvterm

    # Doom LSP y desarrollo
    nodePackages.intelephense
    tree-sitter

    # Para clipboard
    xclip

    # Para org-mode
    graphviz
    plantuml

    # Browser
    firefox
    google-chrome

    # SSH y red
    openssh
    networkmanager

    # Audio
    alsa-utils
    pavucontrol

    # Teams
    teams-for-linux
  ];

  # Home Manager Configuration
  home-manager.users.passh = { pkgs, ... }: {
    home.stateVersion = "24.05";

    services.dunst = {
      enable = true;
      settings = {
        global = {
          # Configuración de la pantalla
          monitor = 0;
          follow = "mouse";
          width = 300;
          height = 300;
          origin = "top-right";
          offset = "10x50";
          scale = 0;
          notification_limit = 20;

          # Progreso
          progress_bar = true;
          progress_bar_height = 10;
          progress_bar_frame_width = 1;
          progress_bar_min_width = 150;
          progress_bar_max_width = 300;

          # Configuración visual
          transparency = 15;
          separator_height = 2;
          padding = 8;
          horizontal_padding = 8;
          text_icon_padding = 0;
          frame_width = 2;
          gap_size = 5;
          separator_color = "frame";
          sort = true;
          idle_threshold = 120;

          # Texto
          font = "JetBrains Mono 10";
          line_height = 0;
          markup = "full";
          format = "<b>%s</b>\\n%b";
          alignment = "left";
          vertical_alignment = "center";
          show_age_threshold = 60;
          word_wrap = true;
          ellipsize = "middle";
          ignore_newline = false;
          stack_duplicates = true;
          hide_duplicate_count = false;
          show_indicators = true;

          # Iconos
          enable_recursive_icon_lookup = true;
          icon_position = "left";
          min_icon_size = 32;
          max_icon_size = 128;
          icon_path = "/run/current-system/sw/share/icons/gnome/16x16/status/:/run/current-system/sw/share/icons/gnome/16x16/devices/:/run/current-system/sw/share/icons/gnome/16x16/apps/";

          # Historia
          sticky_history = true;
          history_length = 20;

          # Acciones
          mouse_left_click = "close_current";
          mouse_middle_click = "do_action, close_current";
          mouse_right_click = "close_all";
        };

        # Urgencia Baja
        urgency_low = {
          background = "#222222";
          foreground = "#888888";
          frame_color = "#888888";
          timeout = 10;
        };

        # Urgencia Normal
        urgency_normal = {
          background = "#285577";
          foreground = "#ffffff";
          frame_color = "#4C7899";
          timeout = 10;
        };

        # Urgencia Crítica
        urgency_critical = {
          background = "#900000";
          foreground = "#ffffff";
          frame_color = "#ff0000";
          timeout = 0;
        };
      };
    };
  };

  # Fonts
  fonts.packages = with pkgs; [
    emacs-all-the-icons-fonts
    hack-font
    monoid
    fira-code
    fira-code-symbols
    jetbrains-mono
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    (nerdfonts.override { fonts = [ "FiraCode" "JetBrainsMono" ]; })
  ];

  # Security
  security = {
    rtkit.enable = true;
    polkit.enable = true;
    sudo.wheelNeedsPassword = true;
    pam.loginLimits = [{
      domain = "*";
      type = "soft";
      item = "nofile";
      value = "524288";
    }];
  };

  # Programs
  programs = {
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };

    bash.enableCompletion = true;
  };

  # Nix settings
  nix = {
    settings = {
      auto-optimise-store = true;
      experimental-features = [ "nix-command" "flakes" ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 8d";
    };
  };

  # System version
  system.stateVersion = "24.05";
}
