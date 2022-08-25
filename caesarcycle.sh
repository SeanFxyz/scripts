#/bin/sh

cycle(){
	rot=0
	message=$@
	while [ $(($rot)) -lt 26 ]
	do
		out="$(echo "$message" | caesar $rot)"
		if [ "$nonum" = 'yes' ]
		then
			echo $out
		else
			printf "%02d - $out\n" $(($rot))
		fi
		rot=$(($rot+1))
	done
}

if [ "$1" = '-n' ] || [ "$1" = '--nonumber' ]
then
	nonum='yes'
	shift
	input="$@"
else
	input="$@"
fi

if [ -z "$input" ]
then
	while read line
	do
		cycle $line
	done
else
	cycle $input
fi
