#!/bin/bash
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
	DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
	SOURCE="$(readlink "$SOURCE")"
	[[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
cd "$DIR"

DELAY=3610 # 1 hour ... and 10 seconds, just to be sure :)
AGENT_STRING="Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.8.1.6) Gecko/20070802 SeaMonkey/1.1.4"
HEADERS="Content-Type: application/x-www-form-urlencoded"

echo "Started SteamTrades-AutoBumper"

while true; do
	if [ -d "www.steamgifts.com" ]; then
		rm -rf "www.steamgifts.com"
	fi

	echo "Verifying and updating cookies..."
	wget -U "$AGENT_STRING" -x --quiet --load-cookies cookies.txt --keep-session-cookies "http://www.steamgifts.com/trades" --save-cookies cookies.txt

	if [ -f "www.steamgifts.com/trades" ]; then
		if [ $(grep -c "Sign in through STEAM" "www.steamgifts.com/trades") -ge 1 ]; then
			echo "The cookies have expired, please update them!"
		elif [ -f "trades.lst" ]; then
			while read ID; do
				if [ -n "$ID" ] && [ "$ID" != "#*" ]; then
					echo "Bumping $ID..."

					wget -U "$AGENT_STRING" -x --quiet --load-cookies cookies.txt --keep-session-cookies "http://www.steamgifts.com/trade/$ID/"

					TOKEN=$(python xpath.py www.steamgifts.com/trade/$ID/index.html "/html/body/div[1]/div/div/div[2]/div[1]/div[2]/div/div/div[2]/form/input[1]/@value")
					DO="bump_trade"
					NAME=$(basename $(python xpath.py www.steamgifts.com/trade/$ID/index.html "/html/body/div[1]/div/div/div[2]/div[1]/div[1]/a[2]/@href"))

					wget -U "$AGENT_STRING" --header "$HEADERS" -x --quiet --load-cookies cookies.txt --header="Content-Type: application/x-www-form-urlencoded" --post-data="xsrf_token=$TOKEN&do=$DO" "http://www.steamgifts.com/trade/$ID/$NAME"
				fi
			done < "trades.lst"
		else
			echo "No 'trades.lst' file present"
  	fi
	fi

	echo "Waiting $DELAY seconds..."
	sleep $DELAY
done
