#!/bin/bash

trap 'echo -ne "\e[?25h"' EXIT # returns the cursor

echo -ne "\e[?25l" # hides cursor
(( ysize=10 )) # may not work as intended on higher numbers due to $RANDOM
(( xsize=10 ))
(( direction=0 )) # default
(( difficulty=10 )) # default, 2difficulty = #traps
(( playerX=${RANDOM:1:1}+1 )) # get second number of random
(( playerY=${RANDOM:1:1}+1 )) # random numbers are 0-9, +1 = inside the grid
(( print=1 ))
(( back=1 ))

# forward() : move the player in the direction it's pointing

forward() {
  case $direction in
    0) (( playerY-- )) ;;
    1) (( playerX++ )) ;;
    2) (( playerY++ )) ;;
    3) (( playerX-- )) ;;
  esac
  validate
  drawmap
}


# left() and right() : change direction based on numbers
# 0 = up    (^)
# 1 = right (>)
# 2 = down  (v)
# 3 = left  (<)

left() {
  if (( direction==0 )); then
    (( direction=3 ))
  else
    (( direction-- ))
  fi
  drawmap
}

right() {
  if (( direction==3 )); then
    (( direction=0))
  else
    (( direction++ ))
  fi
  drawmap
}


# player() : update player facing direction (cosmetic)

player() {
  case $direction in
    0) playerDirection="^" ;;
    1) playerDirection=">" ;;
    2) playerDirection="v" ;;
    3) playerDirection="<" ;;
  esac
}


# genmap() : generates traps and objective

genmap() {
  (( trapnumber=difficulty * 2 ))
  (( objectiveX=${RANDOM:1:1}+1 , objectiveY=${RANDOM:1:1}+1 ))

  for i in $(seq $trapnumber); do
    traps+=( "$(( ${RANDOM:1:1}+1 )),$(( ${RANDOM:1:1}+1 ))" )
  done
}


# validate() : validates player position and assigns lose/win conditions

validate() {
  (( playerX==objectiveX && playerY==objectiveY )) && wincond

  (( playerX<0 || playerX>10 )) && losecond "Out of bounds"

  (( playerY<0 || playerY>10 )) && losecond "Out of bounds"

  # if player is in one of the traps
  for i in "${!traps[@]}"; do
    (( playerX==${traps[i-1]%,*} && playerY==${traps[i-1]#*,} )) && losecond "Fell in a trap!"
  done
}

losecond() {
  # go down 3 lines + newline
  echo -e "\033[3B"
  echo -e "You lost!\nReason: $1"
  restartgame
}

wincond() {
  echo -e "\033[3B"
  echo "You successfully reached the objective!"
  echo "Movement number to beat: ${#input}"
  restartgame # this gets ignored for some reason
}


# append() : drawmap() helper function

append() {
  [[ -z "$line" ]] && line="$1" || line="$line $1"
}


# drawmap() : draws the map to the screen

drawmap() {
  player
  for (( drawY = 1 ; drawY < ysize+1 ; drawY++ )); do

    for (( drawX = 1 ; drawX < xsize+1; drawX++ )); do

      # if current position is the objetive
      (( drawX==objectiveX && drawY==objectiveY )) && {
        append "X"
        continue
      }

      # if current position is the player
      if (( drawX==playerX && drawY==playerY )); then
        append "$playerDirection"
      else

        # check if current position is one of the traps
        for i in "${!traps[@]}"; do
          # parameter expansions to remove after and before the ","
          (( drawX==${traps[i-1]%,*} && drawY==${traps[i-1]#*,} )) && {
            append "T"
            (( trapflag=1 ))
            break
          }
        done

        # current position is none of the above
        (( trapflag!=1 )) && append "#"
        (( trapflag=0 ))

      fi
    done

    # go back 4 lines (position,objetive and command)
    if (( back==0 )); then
      echo -e "\033[5A"
      (( back++ ))
    fi

    # if not first print, go back 10 lines
    if (( print==0 )); then
      echo -e "\033[10A\033[0K$line"
      print=1
    else
      echo -e "$line"
    fi
    unset line

  done
  (( print=0 ))
  (( startflag==0 )) && back=0
  (( startflag==1 )) && sleep 0.5 # let player see the movement
}


showcursor() {
  echo -ne "\e[?25h"
}

tutorial() {
  cat <<END
# # T # # <-- a trap (kills you)
# # ^ # # <-- you (the player)
# # X # # <-- the objective (get here to win)"

Move forward writing "w", turn left using "q" or right using "e"

Example input: wweewwwqwweewwww

END
}


# game() : starts the game

game() {

  genmap
  drawmap
  echo "Your position: $playerX, $playerY"
  echo "Objetive is at $objectiveX, $objectiveY"
  read -rp "Your commands: " input
  echo "-------------------------"
  # signal the game is started
  (( startflag=1 ))

  # movement parsing
  while read -rn1 part; do
    case $part in
      w) forward;;
      q) left   ;;
      e) right  ;;
    esac
  done <<< "$input"

  # in case wincond is not triggered
  losecond "Did not reach objetive"
}


# restartgame() : restarts the game

restartgame() {
  read -rp "Retry? (y/N): " option
  case $option in
    [yY*]) unset input, part, traps; back=1; print=1; startflag=0; echo; game ;;
    *) exit
  esac
}


options=( "Play the game" "Tutorial" "Quit" )
select option in "${options[@]}" ; do
  case $option in
    "Play the game") game ;;
    "Tutorial") tutorial ;;
    "Quit") exit ;;
  esac
done
