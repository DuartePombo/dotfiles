#!/usr/bin/env bash

# Terminate already running bar instances
# If all your bars have ipc enabled, you can use 
polybar-msg cmd quit
# Otherwise you can use the nuclear option:
# killall -q polybar


# Launch Polybar on all connected monitors
for m in $(polybar --list-monitors | cut -d":" -f1); do
	MONITOR=$m polybar --reload bar &
done



echo "Bars launched..."
#!/bin/bash

# Kill existing Polybar instances
killall -q polybar

# Wait until Polybar has shut down
while pgrep -x polybar >/dev/null; do sleep 1; done

# Detect connected monitors
MONITORS=$(polybar --list-monitors | cut -d":" -f1)
MONITOR_ARRAY=($MONITORS)

# Assign specific bars to each monitor
if [[ ${#MONITOR_ARRAY[@]} -ge 2 ]]; then
    MONITOR=${MONITOR_ARRAY[0]} polybar --reload mainbar-primary &
    MONITOR=${MONITOR_ARRAY[1]} polybar --reload mainbar-secondary &
else
    MONITOR=${MONITOR_ARRAY[0]} polybar --reload mainbar-primary &
fi

