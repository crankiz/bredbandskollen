#!/bin/bash
LOGPATH=/home/$USER
URL="https://maker.ifttt.com/trigger/speedtest/with/key/"
SECRET_KEY="SECRET_KEY"
FORMAT=""
DATE=$(date +%Y-%m-%d)
TIME=$(date +%H:%M:%S)

# Checking for dependencies and install
DPKG_QUERY=$(dpkg -s bbk-cli 2>/dev/null|grep -c "ok installed")
if [ $DPKG_QUERY -eq 0 ]; then
  ARCH=$(dpkg --print-architecture)
  TEMP_DEB="$(mktemp)" &&
    wget -O "$TEMP_DEB" https://beta1.bredbandskollen.se/download/bbk-cli_0.3.8_$ARCH.deb &&
    sudo dpkg -i "$TEMP_DEB"
    rm -f "$TEMP_DEB"
fi

usage() {
        echo "Usage: $0 [-c|-h|-i]"
        echo " -c, --csv        Outputs log to CSV"
        echo " -h, --html       Outputs log to HTML"
        echo " -i, --ifttt      Upload result to IFTTT"
}

# Function for  CSV file
csv() {
  echo -e "Date;Time;Latency;Download;Upload"
}

# Function for HTML file
html() {
  echo '<html>
        <head>
          <style>
                table, th, td {
                border: 1px solid black;
                }
          </style>
        </head>
        <body>
         <table>
         <tr><th>Date</th><th>Time</th><th>Latency</th><th>Download</th><th>Upload</th></tr>'
}


speedtest() {
  bbk_cli --quiet|cut -d" " -f-3|tr " " ";"
}


while true; do
    case "$1" in
        -c|--csv ) FORMAT=".csv"
             LOGFILE=$LOGPATH/bbk$FORMAT
              if [ ! -f $LOGFILE ]; then
                csv > $LOGFILE
              fi
             RESULT=$(speedtest)
             echo "$DATE;$TIME;$RESULT" >> $LOGFILE
             exit 0
             ;;
        -h|--html ) FORMAT=".html"
             LOGFILE=$LOGPATH/bbk$FORMAT
              if [ ! -f $LOGFILE ]; then
                html > $LOGFILE
              fi
             RESULT=$(speedtest)
             echo "$DATE;$TIME;$RESULT"|sed -e 's/^/<tr><td>/' -e 's/;/<\/td><td>/g' -e 's/$/<\/td><\/tr>/' >> $LOGFILE
             exit 0
             ;;
        -i|--ifttt )
             RESULT=$(speedtest)
             LATENCY=$(echo $RESULT|cut -d";" -f1)
             DOWNLOAD=$(echo $RESULT|cut -d";" -f2)
             UPLAOD=$(echo $RESULT|cut -d";" -f3)
             JSON="{\"value1\":\"${LATENCY}\",\"value2\":\"${DOWNLOAD}\",\"value3\":\"${UPLOAD}\"}"
             curl -X POST -H "Content-Type: application/json" -d "${JSON}" $URL${SECRET_KEY}
             exit 0
             ;;
        * ) if [ -z "$1" ]; then
               usage
              exit 0
           fi
           ;;
    esac
    shift
done
