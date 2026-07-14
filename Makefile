help:           ## Show this help.
	@grep -F -h "##" $(MAKEFILE_LIST) | grep -F -v grep | sed -e "s/\\$$//" | sed -e "s/##//"

FIND=find
# use env var PRESENTAION_NAME=presentation
NAME=Vortrag_Frauenfeld_BZT_2026
QMD=index.qmd

PORT=5050
DOCS_PATH=current/

IMG_DIR_ORIG=$(HOME)/Projects/wsp-images/

# target paths
IMG_DIR = $(DOCS_PATH)/images
DOCS_TAR_PATH=$(NAME).tar.gz
REMOTE_PATH=~/
AWS_PREFIX=/usr/share/nginx/
LOC_PREFIX=/usr/share/nginx/
INTERAKTIV=html/interaktiv/
SERVER = aws-server

# quarto paths
QUARTO_PRJ=$(HOME)/Projects/Quarto
QUARTO_FRONTEND_DIR=$(QUARTO_PRJ)/interaktiv-frontend/
QUARTO_BACKEND_DIR=$(QUARTO_PRJ)/interaktiv-backend/

# Convert paths to the correct format for Windows
ifeq ($(OS), Windows_NT)
    # IMG_DIR := $(subst /,\\,$(IMG_DIR))
	FIND=gfind
endif

upload-js:
	cd ../interaktiv-frontend && make upload

render:         ## Render the markdown with quarto into DOCS_PATH
	@mkdir -p $(DOCS_PATH)/images
	@cp -rf images/icons $(DOCS_PATH)/images/
	@quarto render $(QMD) --output-dir $(DOCS_PATH)

images:
	ln -s $(IMG_DIR_ORIG) images

convert:		## Convert the png and jpq to webp (TODO)
	find images -type f \( -iname "*.png" -o -iname "*.jpg" \) -exec sh -c 'cwebp "$$1" -q 80 -o "$${1%.*}.webp"' _ {} \;

serve:          ## Serves the project via quarto
serve: render
	quarto preview

upload: render  ## Upload the DOCS_PATH and frontend js to the server
	tar -cvzf $(DOCS_TAR_PATH) $(DOCS_PATH) && \
	scp -r $(DOCS_TAR_PATH) $(SERVER):$(REMOTE_PATH) && \
	ssh $(SERVER) "rm -rf $(AWS_PREFIX)$(INTERAKTIV)$(DOCS_PATH)" && \
	ssh $(SERVER) "tar -xvf $(REMOTE_PATH)$(DOCS_TAR_PATH) -C $(AWS_PREFIX)$(INTERAKTIV)" && \
	cd $(QUARTO_FRONTEND_DIR) && make build DOCS_PATH=$(DOCS_PATH) && make upload DOCS_PATH=$(DOCS_PATH)

load: render    ## load DOCS_PATH and frontend js to local nginx server
	echo "Loading $(DOCS_PATH) and frontend js to local nginx server..."
	mkdir -p $(LOC_PREFIX)$(INTERAKTIV)$(DOCS_PATH)
	cp -r $(DOCS_PATH)/* $(LOC_PREFIX)$(INTERAKTIV)$(DOCS_PATH)
	cd  $(QUARTO_FRONTEND_DIR) && make build_local DOCS_PATH=$(DOCS_PATH) && make load DOCS_PATH=$(DOCS_PATH)

interaktive.run:## Run the interactive backend server
	cd $(QUARTO_BACKEND_DIR) && make run

firefox: render  ## Open non caching version in firefox
	firefox --no-remote --profile firefox.profile/

dev:			## Serves the project in development mode
dev: ## Serve project in development mode
	@echo "🔍 Checking if port $(PORT) is in use..."
	@if ss -lnt | grep -q ":$(PORT) "; then \
		echo "❌ Port $(PORT) is already in use. Maybe Docker or another process is running."; \
		echo "❌ Properly we are using nginx as a local server, please stop it or change the port."; \
	else \
		echo "✅ Port $(PORT) is free. Starting development server..."; \
		cd $(DOCS_TAR_PATH) && python -m http.server $(PORT); \
	fi

docs:           ## Copy DOCS_PATH to docs for github pages
	rm -rf docs/
	mkdir -p docs/
	cp -r $(DOCS_PATH)/* docs/

clean:          ## clean up
	rm -rf $(DOCS_PATH)
	rm -rf .quarto
	rm -rf node_modules
	find . -type f -name '*~' -delete

docker.clean:
	docker stop $(docker ps -aq) 2>/dev/null || true
	docker rm -f $(docker ps -aq) 2>/dev/null || true
	docker rmi -f $(docker images -aq) 2>/dev/null || true
	docker volume rm $(docker volume ls -q) 2>/dev/null || true
	docker system prune -f
	docker system prune -a --volumes -f
	@echo "Docker cleanup completed."