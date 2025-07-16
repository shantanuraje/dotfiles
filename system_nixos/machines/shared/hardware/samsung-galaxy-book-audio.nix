# Samsung Galaxy Book Audio Fix Module
# Hardware: SAMSUNG ELECTRONICS CO., LTD. NP930QCG-K01US
# CPU: Intel i7-1065G7
# 
# This module provides the audio fix for Samsung Galaxy Book laptops.
# Can be imported by both personal and work machine configurations.
#
# Original fix from: https://forum.manjaro.org/t/howto-set-up-the-audio-card-in-samsung-galaxy-book/37090

{ config, pkgs, lib, ... }:

let
  # Audio fix script from https://pastebin.com/raw/zsXp2vz6
  # This is the ACTUAL working script that fixes Samsung Galaxy Book audio
  audioFixScript = pkgs.writeScript "TO912.sh" ''
    #!/bin/bash
    # Samsung Galaxy Book Audio Fix Script - Original from pastebin
    # Hardware-specific HDA verb commands for Samsung NP930QCG-K01US
    
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x1a SET_PIN_WIDGET_CONTROL 0x5
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x2b
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0xc00 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x2b
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x40c 0x10
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x3
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x42
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x5
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x42b 0xe0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x8
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x42f 0xcf
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0xe
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x46f 0x80
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0xf
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x62
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x10
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x40e 0x21
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x11
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x19
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x17
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x2b
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x40c 0x10
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x2d
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4c0 0x20
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x30
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x424 0x21
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x32
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x43f 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x4f
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4b0 0x29
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x50
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x410 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x55
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x480 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x80
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x11
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x82
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x444 0x8
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x99
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x480 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x22
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x3a
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x26
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0xc00 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x404 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4b0 0x11
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x26
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0xc00 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x404 0x1
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x1
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4b0 0x11
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x26
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0xc00 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x18
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x1
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4b0 0x11
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x26
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0xc00 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x19
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4b0 0x11
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x26
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0xc00 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x20
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0xc0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4b0 0x11
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x26
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0xc00 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x22
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x44
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4b0 0x11
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x26
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0xc00 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x8
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4b0 0x11
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x26
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0xc00 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x24
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x85
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4b0 0x11
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x26
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0xc00 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x25
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4b0 0x11
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x26
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4b0 0x11
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x26
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0xc00 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x35
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x40
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4b0 0x11
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x26
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0xc00 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x36
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x1
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4b0 0x11
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x26
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0xc00 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x38
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x81
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4b0 0x11
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x26
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0xc00 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x3a
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x3
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4b0 0x11
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x26
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0xc00 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x3b
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x81
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4b0 0x11
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x26
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0xc00 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x40
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x3e
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4b0 0x11
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x26
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0xc00 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x41
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x7
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4b0 0x11
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x26
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0xc00 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x404 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x1
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4b0 0x11
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x26
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0xc00 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x404 0x1
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4b0 0x11
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x22
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x39
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x26
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0xc00 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x26
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0xc00 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x404 0x1
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x1
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4b0 0x11
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x26
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0xc00 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x18
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x2
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4b0 0x11
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x26
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0xc00 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x19
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4b0 0x11
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x26
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0xc00 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x20
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0xc0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4b0 0x11
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x26
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0xc00 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x22
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x44
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4b0 0x11
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x26
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0xc00 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x8
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4b0 0x11
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x26
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0xc00 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x24
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x85
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4b0 0x11
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x26
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0xc00 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x25
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x41
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4b0 0x11
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x26
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0xc00 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x26
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x1
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4b0 0x11
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x26
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0xc00 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x35
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x40
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4b0 0x11
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x26
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0xc00 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x36
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x1
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4b0 0x11
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x26
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0xc00 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x38
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x81
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4b0 0x11
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x26
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0xc00 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x3a
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x3
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4b0 0x11
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x26
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0xc00 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x3b
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x81
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4b0 0x11
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x26
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0xc00 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x40
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x3e
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4b0 0x11
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x26
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0xc00 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x41
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x7
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4b0 0x11
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x26
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0xc00 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x404 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x1
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4b0 0x11
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x26
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0xc00 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x404 0x1
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4b0 0x11
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x22
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x39
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x26
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0xc00 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x404 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4b0 0x11
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x22
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x39
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x26
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0xc00 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x404 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4b0 0x11
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x4f
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0xc00 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x4f
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4b0 0x29
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x5
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0xc00 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x5
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x42b 0xe0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x0 0xf00 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x30
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0xc00 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x30
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x424 0x21
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x22
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x3a
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x26
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0xc00 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x404 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x1
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4b0 0x11
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x22
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x39
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x26
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0xc00 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x404 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x1
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4b0 0x11
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x10
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0xc00 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x10
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x40f 0x21
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x11
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0xc00 0x0
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x11
  '';
in
{
  # Audio packages required for Samsung Galaxy Book
  environment.systemPackages = with pkgs; [
    sof-firmware      # Sound Open Firmware for Intel audio
    alsa-tools        # ALSA configuration tools  
    alsa-utils        # ALSA utilities (amixer, etc.)
  ];
  
  # Kernel module configuration for Samsung Galaxy Book audio
  boot.extraModprobeConfig = ''
    # Force SOF driver for Samsung Galaxy Book audio
    options snd slots=snd_soc_skl_hda_dsp
    
    # Blacklist problematic Intel HDA driver  
    blacklist snd-hda-intel
  '';
  
  # Kernel parameters for Samsung Galaxy Book
  boot.kernelParams = [
    "snd_hda_intel.enable=0"          # Disable Intel HDA
    "snd_soc_skl_hda_dsp.enable=1"    # Enable SOF driver
  ];
  
  # Use PulseAudio instead of PipeWire for this hardware
  hardware.pulseaudio.enable = lib.mkForce true;
  hardware.pulseaudio.support32Bit = true;
  hardware.pulseaudio.configFile = pkgs.writeText "samsung-pulseaudio.pa" ''
    # Samsung Galaxy Book PulseAudio configuration
    .include ${pkgs.pulseaudio}/etc/pulse/default.pa
    
    # Disable suspend-on-idle to prevent audio issues
    # (commenting out module-suspend-on-idle)
    
    # Force load SOF module for Samsung Galaxy Book
    load-module module-alsa-sink device=hw:0,0
    load-module module-alsa-source device=hw:0,0
  '';
  
  # Disable PipeWire (conflicts with PulseAudio fix)
  services.pipewire.enable = lib.mkForce false;
  services.pipewire.alsa.enable = lib.mkForce false;
  services.pipewire.pulse.enable = lib.mkForce false;
  
  # Systemd service for audio fix at boot
  systemd.services.samsung-audio-fix = {
    description = "Samsung Galaxy Book Audio Fix";
    wantedBy = [ "multi-user.target" ];
    after = [ "sound.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${audioFixScript}";
      RemainAfterExit = true;
    };
  };
  
  # Systemd service for audio fix after suspend/resume  
  systemd.services.samsung-audio-fix-resume = {
    description = "Samsung Galaxy Book Audio Fix (Post-Suspend)";
    wantedBy = [ "suspend.target" ];
    after = [ "suspend.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${audioFixScript}";
    };
  };
  
  # ALSA configuration
  environment.etc."alsa/conf.d/99-samsung-galaxy-book.conf".text = ''
    # Samsung Galaxy Book ALSA configuration
    defaults.pcm.card 0
    defaults.ctl.card 0
  '';
  
  # Hardware identification file for documentation
  environment.etc."hardware-profile/samsung-galaxy-book.txt".text = ''
    Samsung Galaxy Book Audio Fix Applied
    =====================================
    
    Hardware: SAMSUNG ELECTRONICS CO., LTD. NP930QCG-K01US
    CPU: Intel i7-1065G7
    
    Audio Fix Components:
    - SOF firmware enabled
    - Intel HDA driver blacklisted  
    - Custom PulseAudio configuration
    - Boot and resume audio services
    
    References:
    - https://forum.manjaro.org/t/howto-set-up-the-audio-card-in-samsung-galaxy-book/37090
    - https://pastebin.com/raw/zsXp2vz6
    - Kernel bug: https://bugzilla.kernel.org/show_bug.cgi?id=207423
    
    Module: machines/shared/hardware/samsung-galaxy-book-audio.nix
  '';
}