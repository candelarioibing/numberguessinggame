#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

echo "Enter your username:"
read -r USERNAME
USERNAME_ESCAPED=$(printf '%s' "$USERNAME" | sed "s/'/''/g")
USER_ID=$($PSQL "SELECT user_id FROM users WHERE username='$USERNAME_ESCAPED'")

if [[ -z "$USER_ID" ]]; then
  $PSQL "INSERT INTO users(username) VALUES('$USERNAME_ESCAPED')" > /dev/null
  USER_ID=$($PSQL "SELECT user_id FROM users WHERE username='$USERNAME_ESCAPED'")
  echo "Welcome, $USERNAME! It looks like this is your first time here."
else
  GAMES_PLAYED=$($PSQL "SELECT COUNT(*) FROM games WHERE user_id=$USER_ID")
  BEST_GAME=$($PSQL "SELECT MIN(number_of_guesses) FROM games WHERE user_id=$USER_ID")
  echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

SECRET_NUMBER=$((RANDOM % 1000 + 1))
NUMBER_OF_GUESSES=1
echo "Guess the secret number between 1 and 1000:"
read -r GUESS

while true; do
  if [[ ! "$GUESS" =~ ^[+-]?[0-9]+$ ]]; then
    echo "That is not an integer, guess again:"
  else
    if [[ "$GUESS" == -* ]]; then
      GUESS_VALUE=$((-10#${GUESS#-}))
    else
      GUESS_VALUE=$((10#${GUESS#+}))
    fi

    if (( GUESS_VALUE == SECRET_NUMBER )); then
      break
    elif (( GUESS_VALUE < SECRET_NUMBER )); then
      echo "It's higher than that, guess again:"
    else
      echo "It's lower than that, guess again:"
    fi
  fi

  read -r GUESS
  ((NUMBER_OF_GUESSES++))
done

echo "You guessed it in $NUMBER_OF_GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!"
$PSQL "INSERT INTO games(user_id, number_of_guesses) VALUES($USER_ID, $NUMBER_OF_GUESSES)" > /dev/null