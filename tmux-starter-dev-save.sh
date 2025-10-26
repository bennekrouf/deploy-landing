#!/bin/sh

SESSION="api0"
PROJECT_ROOT="$HOME/code/api0"

tmux kill-session -t "$SESSION" 2>/dev/null

run_with_fallback() {
  printf "%s; exec $SHELL -l" "$1"
}

# Set pane labels globally
tmux set -g pane-border-status top
tmux set -g pane-border-format "#{?@label,#{@label},#{pane_index} #{pane_current_command}}"

# 1. store
tmux new-session -d -s "$SESSION" -c "$PROJECT_ROOT/store" \
  "$(run_with_fallback "export DATABASE_URL='postgresql://api_store_dev_user:Salma2025!@localhost:5433/api-store-dev' && cargo watch -x run")"
tmux select-pane -t "$SESSION:0.0" -T "store"

# 2. semantic
tmux split-window -h -c "$PROJECT_ROOT/semantic" -t "$SESSION" \
  "$(run_with_fallback "sleep 5 && cargo run -- --provider claude --api http://0.0.0.0:50057")"
tmux select-pane -t "$SESSION:0.1" -T "semantic"

# 3. dashboard
tmux split-window -v -c "$PROJECT_ROOT/dashboard" -t "$SESSION" \
  "$(run_with_fallback "yarn dev")"
tmux select-pane -t "$SESSION:0.2" -T "dashboard"

# 4. ai-uploader
tmux split-window -h -c "$PROJECT_ROOT/ai-uploader" -t "$SESSION" \
  "$(run_with_fallback "COHERE_API_KEY='yTic1IyNddYd99KdwScBibnOEhtTzCb2Goy2wVfp' cargo watch -x run")"
tmux select-pane -t "$SESSION:0.3" -T "ai-uploader"

# 5. gateway
tmux split-window -v -c "$PROJECT_ROOT/gateway" -t "$SESSION" \
  "$(run_with_fallback "RUST_LOG=debug API0__SERVER__PORT=5009 AI_UPLOADER_URL=http://0.0.0.0:6666 cargo run")"
tmux select-pane -t "$SESSION:0.4" -T "gateway"

tmux attach -t "$SESSION"
