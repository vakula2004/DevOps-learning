#!/bin/bash
index ()    
{
    pidfile="$2"
    index_file="$1"
    PID=$(cat "$pidfile")
    PS=$(ps -Fj -p "$PID")

printf "%s$PS" > /tmp/ps.txt
sed -i 's/$/<br>/' /tmp/ps.txt
    PS=$(cat /tmp/ps.txt)
echo -e '<!DOCTYPE html>\n' >> "$index_file"
echo -e '<html>\n' >> "$index_file"
echo -e '<head>\n' >> "$index_file"
echo -e '          <title>Listing of processings</title> \n' >> "$index_file"
echo -e '     </head> \n' >> "$index_file"
echo -e '     <body>   \n' >> "$index_file"
printf  "%s$PS"  >> "$index_file"
echo -e '    </body> \n' >> "$index_file"
echo -e '</html> \n' >> "$index_file"
rm /tmp/ps.txt
}