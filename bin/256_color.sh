#!/bin/bash

for fgbg in 38 48 ; do # Foreground / Background
  for color in {1..255} ; do # Colors
    # Display the color
    printf "\e[${fgbg};5;%sm  %3s  \e[0m" $color $color
    # Display XXX colors per lines
    if [ $((($color) % 30)) == 0 ] ; then
      echo # New line
    fi
  done
  echo # New line
done

exit 0
