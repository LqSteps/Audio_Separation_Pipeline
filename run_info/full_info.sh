#!/usr/bin/env bash
tmux kill-session -t main 2>/dev/null
tmux new-session -d -s main
tmux split-window -v
tmux split-window -h -t main:0.0
tmux send-keys -t main:0.0 'bash queue.sh' Enter
tmux send-keys -t main:0.1 'bash progress.sh' Enter
tmux send-keys -t main:0.2 'watch -t journalctl -fu demucs_pipeline.service' Enter
tmux attach -t main
