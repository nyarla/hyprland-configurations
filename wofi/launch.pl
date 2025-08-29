#!/usr/bin/env perl

use v5.40;
use utf8;

sub launch {
  my $cmd = shift;
  return sub {
    exec($cmd);
  };
}

sub sep : prototype($) {
  my $label = shift;
  return ( sep => "<b># ${label}</b>" );
}

sub wine : prototype($) {
  state $prefix ||= '/etc/nixos/dotfiles/files/wine';
  my $cmd = shift;
  return "bash '${prefix}/${cmd}'";
}

sub script : prototype($) {
  state $prefix ||= '/etc/nixos/dotfiles/files/scripts';
  my $cmd = shift;
  return "bash '${prefix}/${cmd}'";
}

sub jack : prototype($) {
  state $rate   ||= 'pw-metadata -n settings 0 clock.force-rate 96000';
  state $buffer ||= 'pw-metadata -n settings 0 clock.force-quantum 512';

  my $cmd = shift;
  return "bash -c '${rate} ; ${buffer} ; QT_QPA_PLATFORM=xcb GDK_BACKEND=x11 pw-jack ${cmd}'";
}

sub nosleep : prototype($) {
  state $prefix = 'systemd-inhibit --what=idle ';
  my $cmd = shift;
  return "${prefix} ${cmd}";
}

sub apps {
  ## defaults
  state $terminal  ||= 'mlterm-wl';
  state $browser   ||= 'firefox';
  state $email     ||= 'thunderbird';
  state $password  ||= 'bitwarden --enable-features=UseOzonPlatform --ozone-platform=wayland --enable-wayland-ime';
  state $text      ||= 'pluma';
  state $documents ||= 'atril';
  state $ebooks    ||= 'calibre';
  state $music     ||= nosleep 'deadbeef';
  state $video     ||= nosleep 'vlc';
  state $files     ||= 'Thunar';
  state $calc      ||= 'mate-calc';
  state $charmap   ||= 'gucharmap';
  state $scanner   ||= 'simple-scan';
  state $audio     ||= 'pwvucontrol';
  state $bluetooth ||= 'blueman-manager';
  state $keychain  ||= 'seahorse';
  state $taskmgr   ||= 'missioncenter';
  state $apps      ||= [
    sep "Defaults",
    terminal  => launch($terminal),
    browser   => launch($browser),
    email     => launch($email),
    password  => launch($password),
    text      => launch($text),
    documents => launch($documents),
    ebooks    => launch($ebooks),
    music     => launch($music),
    video     => launch($video),
    files     => launch($files),
    calc      => launch($calc),
    charmap   => launch($charmap),
    scanner   => launch($scanner),

    sep "Common",
    'mlterm' => launch($terminal),
    'vial'   => launch('Vial'),

    sep "Virtual Machine",
    'virt-manager'         => launch( nosleep 'virt-manager' ),
    'looking-glass-client' => launch( nosleep 'looking-glass-client' ),
    'remmina'              => launch( nosleep 'remmina' ),
    'take-snapshot'        => launch( script 'vm-snapshot-for-daw' ),
    'waydroid-start'       => launch( script 'waydroid-start' ),
    'waydroid-stop'        => launch( script 'waydroid-stop' ),

    sep "Internet",
    'firefox'         => launch($browser),
    'firefox-private' => launch('firefox -p private'),
    'thunderbird'     => launch($email),
    'bitwarden'       => launch($password),
    'google-chrome'   => launch('google-chrome-stable --ozone-platform=wayland --enable-wayland-ime'),
    'telegram'        => launch('Telegram'),

    sep "Files",
    'Thunar'   => launch($files),
    'calibre'  => launch($ebooks),
    'kindle'   => launch( nosleep wine 'Kindle' ),
    'atril'    => launch($documents),
    'deadbeef' => launch($music),
    'vlc'      => launch($video),
    'pluma'    => launch($text),
    'picard'   => launch('picard'),
    'easytag'  => launch('easytag'),

    sep "Office",
    'mate-calc'   => launch($calc),
    'libreoffice' => launch('libreoffice'),
    'simple-scan' => launch($scanner),
    'gucharmap'   => launch($charmap),

    sep "Game / VR",
    'steam'    => launch( nosleep 'steam' ),
    'wivrn'    => launch( nosleep script('launch-wivrn') ),
    'immersed' => launch( nosleep script('launch-immersed') ),

    sep "System",
    'pwvucontrol'     => launch($audio),
    'blueman-manager' => launch($bluetooth),
    'droidcam'        => launch('droidcam'),
    'seahorse'        => launch($keychain),
    'missioncenter'   => launch($taskmgr),

    sep "Illustrations",
    'gimp'       => launch( nosleep 'amd-run gimp' ),
    'krita'      => launch( nosleep 'amd-run krita' ),
    'inkscape'   => launch( nosleep 'amd-run inkscape' ),
    'pixelorama' => launch( nosleep 'pixelorama --rendering-driver vulkan --gpu-index 0 --display-driver wayland' ),
    'aseprite'   => launch( nosleep 'aseprite' ),

    sep "Musics",
    'bitwig-studio'     => launch( nosleep jack 'bitwig-studio' ),
    'heilo-workstation' => launch( nosleep jack 'helio' ),
    'musescore'         => launch( nosleep jack 'mscore' ),
    'zrythm'            => launch( nosleep jack script 'zrythm-launch' ),
    'famistudio'        => launch( nosleep 'FamiStudio' ),
    'sononym'           => launch( nosleep jack 'sononym' ),
    'carla'             => launch( nosleep jack 'carla' ),
    'ildaeil'           => launch( nosleep jack 'Ildaeil' ),
    'audiogridder'      => launch( nosleep jack 'AudioGridder' ),
    'voicevox'          => launch( nosleep 'voicevox' ),
    'openutau'          => launch( nosleep 'OpenUtau' ),

    sep "Generaive AI",
    'stability-matrix' => launch('StabilityMatrix'),
  ];
  return $apps;
}

sub dmenu : prototype(@) {
  state $HOME = $ENV{'HOME'};
  state $wofi = qq|wofi --dmenu --style=${HOME}/.config/hypr/wofi/style.css --color=${HOME}/.config/hypr/wofi/colors --allow-markup|;

  my $out = `rm "${HOME}/.cache/wofi-dmenu"; echo "@{[ join qq{\n}, @_]}" | ${wofi}`;
  chomp($out);

  return $out;
}

sub run : prototype($) {
  my $define = shift;
  my @labels;
  my $actions = {};
  my $nop     = sub { exit 0 };
  while ( my ( $label, $action ) = splice $define->@*, 0, 2 ) {
    push @labels, $label eq 'sep' ? $action : $label;
    if ( $label eq 'sep' ) {
      $actions->{$label} = $nop;
    }
    else {
      $actions->{$label} = $action;
    }
  }

  my $selected = dmenu @labels;
  if ( defined $selected && $selected ne q{} && exists $actions->{$selected} ) {
    return $actions->{$selected}->();
  }

  return $nop->();
}

sub main {
  my $ns      = shift // q{};
  my $actions = {
    apps => apps,
  };

  run( $actions->{$ns} // [] );
}

main(@ARGV);
