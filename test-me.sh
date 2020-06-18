#!/usr/bin/env bash
FILE=.env
if [[ -f "$FILE" ]]; then
  export $(grep -v '^#' .env | xargs)
fi

export TRIES="${TRIES:-10}"
export HOST="${HOST:-127.0.0.1}"
export PORT="${PORT:-3030}"
export DURATION="${DURATION:-3s}"
export WORKERS="${WORKERS:-100}"

echo "----------------------------------------"
echo "Settings:"
echo "----------------------------------------"
echo "Iterating ${TRIES} times"
echo "Loading ${HOST}:${PORT}"
echo "Running for ${DURATION} each iteration"
echo "Using ${WORKERS} workers"
echo "----------------------------------------"

$(lsof -nP -iTCP:3030 | grep LISTEN | awk {'print $2'} | xargs kill -9) 2>/dev/null

FILE=test.pid
if [[ -f "$FILE" ]]; then
  rm -f $FILE
fi

$(cargo build --release 2>/dev/null) 2>/dev/null
cargo run --release 2>/dev/null &
export pid=`echo $!`
echo "Server running on PID: $pid"
sleep 1
echo $pid > $FILE

echo "==============================="
for cnt in `seq 1 ${TRIES}`; do (
    echo "Iteration: $cnt of ${TRIES}" \
		&& echo "-------------------------------" \
		&& start=`/bin/ps -axm -o rss,pid | grep ${pid} | awk {'print $1'}` \
		&& load=`hey -z ${DURATION} -c ${WORKERS} http://${HOST}:${PORT} | grep -E "Requests\/sec\:|99% in"` \
		&& rps=$(echo $load | awk {'print $2'}) \
		&& latency=$(echo $load | awk {'print $5 " " $6'}) \
		&& end=`/bin/ps -axm -o rss,pid | grep ${pid} | awk {'print $1'}` \
		&& echo Requests/sec: $rps \
		&& echo "Latency (worst case): $latency" \
		&& echo "-------------------------------" \
		&& echo Starting memory: $start KB \
		&& echo Ending memory: $end KB \
		&& memory_leaked=`echo $(expr $end - $start)` \
		&& echo Memory leaked: $memory_leaked KB \
		&& echo "===============================" \
	) || break
done
{kill $pid } 2>/dev/null
$(lsof -nP -iTCP:3030 | grep LISTEN | awk {'print $2'} | xargs kill -9) 2>/dev/null
rm -f $FILE > /dev/null

