# Simple token visualization with xload
SHELL := /bin/bash
.PHONY: all clean dashboard stop

PIPE = /tmp/tokenload_pipe
DATA = /tmp/tokenload_data

generators: 
	@mkdir -p /tmp/tokenload
	@for i in 1 2 3; do \
		(while true; do \
			echo "gen$$i: $$((RANDOM % 3000))" >> /tmp/tokenload/gen$$i.log; \
			sleep 1; \
		done) & \
	done

aggregator:
	@(while true; do \
		TOTAL=0; \
		for f in /tmp/tokenload/gen*.log; do \
			VAL=$$(tail -n1 $$f 2>/dev/null | grep -o '[0-9]*$$' || echo 0); \
			TOTAL=$$((TOTAL + VAL)); \
		done; \
		echo $$TOTAL > $(PIPE); \
		echo "[`date '+%H:%M:%S'`] Total: $$TOTAL" > $(DATA); \
		sleep 1; \
	done) &

dashboard: clean
	@mkdir -p /tmp/tokenload
	@mkfifo $(PIPE)
	@touch $(DATA)
	@tmux new-session -d -s tokenviz -n 'TokenViz'
	@tmux split-window -h
	@tmux split-window -h
	@tmux select-layout even-horizontal
	@tmux send-keys -t 0 'tail -f /tmp/tokenload/gen*.log' Enter
	@tmux send-keys -t 1 'tail -f $(DATA)' Enter
	@tmux send-keys -t 2 'DISPLAY=:0 xload -geometry 400x200+100+100 -bg black -fg green -scale 5 < $(PIPE)' Enter
	@tmux select-pane -t 0
	@$(MAKE) generators
	@$(MAKE) aggregator
	@tmux attach -t tokenviz

stop:
	@pkill -f "while true.*gen[123]" || true
	@pkill -f "while true.*TOTAL" || true
	@tmux kill-session -t tokenviz 2>/dev/null || true
	@rm -f $(PIPE) $(DATA)
	@rm -rf /tmp/tokenload

clean: stop
