#!/usr/bin/env bash

readonly ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

tmux kill-session -t main 2>/dev/null
tmux new-session -d -s main
tmux split-window -v
tmux split-window -h -t main:0.0
tmux send-keys -t main:0.0 "bash $ROOT_DIR/run_info/queue.sh" Enter
tmux send-keys -t main:0.1 "bash $ROOT_DIR/run_info/progress.sh" Enter
tmux send-keys -t main:0.2 'docker compose logs -f' Enter
tmux attach -t main
