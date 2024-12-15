#!bash

cleanup() {
    echo "Shutting down all jobs..."
    kill $(jobs -p)
    exit 0
}

trap cleanup SIGINT

for job in jobs/*.py; do
    python "$job" &
done

wait
