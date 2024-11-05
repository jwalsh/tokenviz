# TokenViz Configuration
SHELL := /bin/bash
.PHONY: all clean test dashboard stop setup generators aggregator test-tmux test-xload status logs kill-all restart

# Check if we're in a container and set DISPLAY accordingly
CONTAINER_CHECK := $(shell test -f /.dockerenv && echo 1 || echo 0)
ifeq ($(CONTAINER_CHECK),1)
    XDISPLAY := :1
else
    XDISPLAY := :0
endif

# Paths
PIPE := /tmp/tokenload_pipe
DATA := /tmp/tokenload_data
LOGDIR := /tmp/tokenload
SESSION := tokenviz

setup:
	@echo "Setting up directories and files..."
	@rm -rf $(LOGDIR) || true
	@mkdir -p $(LOGDIR)
	@rm -f $(PIPE) || true
	@mkfifo $(PIPE)
	@touch $(DATA)
	@for i in 1 2 3; do echo "Initializing gen$$i..." > $(LOGDIR)/gen$$i.log; done

generators: setup
	@for i in 1 2 3; do \
		( \
			while true; do \
				if [ -d "$(LOGDIR)" ]; then \
					echo "gen$$i: $$((RANDOM % 3000))" >> "$(LOGDIR)/gen$$i.log"; \
				else \
					exit 0; \
				fi; \
				sleep 1; \
			done \
		) & \
	done

aggregator: setup
        @( \
                while true; do \
                        if [ -d "$(LOGDIR)" ]; then \
                                TOTAL=0; \
                                for f in $(LOGDIR)/gen*.log; do \
                                        if [ -f "$$f" ]; then \
                                                VAL=$$(tail -n1 "$$f" 2>/dev/null | grep -o '[0-9]*$$' || echo 0); \
                                                TOTAL=$$((TOTAL + VAL)); \
                                        fi; \
                                done; \
                                echo "$$TOTAL" > "$(PIPE)" 2>/dev/null || exit 0; \
                                echo "[`date '+%H:%M:%S'`] Total: $$TOTAL" > "$(DATA)" 2>/dev/null || exit 0; \
                        else \
                                exit 0; \
                        fi; \
                        sleep 1; \
                done \
        ) &

dashboard: stop setup
	@echo "Starting dashboard with DISPLAY=$(XDISPLAY)..."
	@tmux new-session -d -s $(SESSION) -n 'TokenViz' \; \
		split-window -h \; \
		split-window -h \; \
		select-layout even-horizontal \; \
		send-keys -t 0 "while true; do clear; tail -n 10 $(LOGDIR)/gen*.log 2>/dev/null || echo 'Waiting for data...'; sleep 1; done" C-m \; \
		send-keys -t 1 "while true; do clear; tail -n 10 $(DATA) 2>/dev/null || echo 'Waiting for data...'; sleep 1; done" C-m \; \
		send-keys -t 2 "DISPLAY=$(XDISPLAY) xload -geometry 400x200+100+100 -bg black -fg green -scale 5 < $(PIPE)" C-m \; \
		select-pane -t 0
	@echo "Starting generators..."
	@$(MAKE) generators
	@echo "Starting aggregator..."
	@$(MAKE) aggregator
	@echo "Attaching to session..."
	@tmux attach -t $(SESSION)

stop:
	@echo "Stopping all processes..."
	@pkill -f "/bin/bash.*while true.*gen" 2>/dev/null || true
	@pkill -f "while true.*TOTAL" 2>/dev/null || true
	@tmux kill-session -t $(SESSION) 2>/dev/null || true
	@rm -f $(PIPE) $(DATA) 2>/dev/null || true
	@rm -rf $(LOGDIR) 2>/dev/null || true
	@echo "All processes stopped"

kill-all:
	@echo "Emergency cleanup in progress..."
	@ps ax | grep "gen.*RANDOM" | grep -v grep | awk '{print $$1}' | xargs kill -9 2>/dev/null || true
	@pkill -f "while true.*TOTAL" 2>/dev/null || true
	@echo "Emergency cleanup complete"

restart: stop dashboard

status:
	@echo "TokenViz Status:"
	@echo "---------------"
	@echo "Environment: $$([ $(CONTAINER_CHECK) -eq 1 ] && echo 'Container' || echo 'Local')"
	@echo "Display: $(XDISPLAY)"
	@echo "\nGenerator processes:"
	@ps ax | grep "while true.*gen" | grep -v grep || echo "No generators running"
	@echo "\nAggregator process:"
	@ps ax | grep "while true.*TOTAL" | grep -v grep || echo "No aggregator running"
	@echo "\nTmux session:"
	@tmux has-session -t $(SESSION) 2>/dev/null && echo "Session $(SESSION) is running" || echo "No session running"

logs:
	@echo "Last 5 lines from each generator:"
	@for i in 1 2 3; do \
		echo "\nGenerator $$i:"; \
		tail -n 5 "$(LOGDIR)/gen$$i.log" 2>/dev/null || echo "No log file"; \
	done
	@echo "\nLast 5 lines from aggregator:"
	@tail -n 5 "$(DATA)" 2>/dev/null || echo "No aggregator data"

test-display:
	@echo "Container detection: $(CONTAINER_CHECK)"
	@echo "Using DISPLAY=$(XDISPLAY)"
	@echo "Testing X11 connection..."
	@if DISPLAY=$(XDISPLAY) xdpyinfo >/dev/null 2>&1; then \
		echo "X11 connection successful"; \
	else \
		echo "X11 connection failed"; \
		exit 1; \
	fi
