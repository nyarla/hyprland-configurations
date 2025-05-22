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

sub wine {
  state $prefix ||= '/etc/nixos/dotfiles/files/wine';
  my $cmd = shift;
  return sub {
    exec("sh '${prefix}/${cmd}'");
  };
}

sub script {
  state $prefix ||= '/etc/nixos/dotfiles/files/scripts';
  my $cmd = shift;
  return sub {
    exec("sh '${prefix}/${cmd}'");
  };
}

sub jack {
  state $rate   ||= 'pw-metadata -n settings 0 clock.force-rate 96000';
  state $buffer ||= 'pw-metadata -n settings 0 clock.force-quantum 512';

  my $cmd = shift;

  return sub {
    exec("sh -c '${rate} ; ${buffer} ; QT_QPA_PLATFORM=xcb GDK_BACKEND=x11 pw-jack ${cmd}'");
  };
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
  state $music     ||= 'deadbeef';
  state $video     ||= 'vlc';
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
    'virt-manager'         => launch('virt-manager'),
    'looking-glass-client' => launch('looking-glass-client'),
    'remmina'              => launch('remmina'),
    'take-snapshot'        => script('vm-snapshot-for-daw'),
    'waydroid-start'       => script('waydroid-start'),
    'waydroid-stop'        => script('waydroid-stop'),

    sep "Internet",
    'firefox'         => launch($browser),
    'firefox-private' => launch('firefox -p private'),
    'thunderbird'     => launch($email),
    'bitwarden'       => launch($password),
    'google-chrome'   => launch('google-chrome-stable --ozone-platform=wayland --enable-wayland-ime'),
    'telegram'        => launch('telegram-desktop'),

    sep "Files",
    'Thunar'   => launch($files),
    'calibre'  => launch($ebooks),
    'kindle'   => wine('Kindle'),
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

    sep "System",
    'pwvucontrol'     => launch($audio),
    'blueman-manager' => launch($bluetooth),
    'droidcam'        => launch('droidcam'),
    'seahorse'        => launch($keychain),
    'missioncenter'   => launch($taskmgr),

    sep "Illustrations",
    'gimp'       => launch('gimp'),
    'krita'      => launch('krita'),
    'inkscape'   => launch('inkscape'),
    'pixelorama' => launch('pixelorama --rendering-driver vulkan --gpu-index 0 --display-driver wayland'),
    'aseprite'   => launch('aseprite'),

    sep "Musics",
    'bitwig-studio'     => jack('bitwig-studio'),
    'heilo-workstation' => jack('helio'),
    'musescore'         => jack('mscore'),
    'zrythm'            => jack('bash /etc/nixos/dotfiles/files/scripts/zrythm-launch'),
    'famistudio'        => launch('FamiStudio'),
    'sononym'           => jack('sononym'),
    'carla'             => jack('carla'),
    'ildaeil'           => jack('Ildaeil'),
    'audiogridder'      => jack('AudioGridder'),
    'voicevox'          => launch('voicevox'),
    'openutau'          => launch('OpenUtau'),
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
