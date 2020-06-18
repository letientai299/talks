# Self documented Makefile
# http://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
help: ## Show list of make targets and their description
	@grep -E '^[/%.a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

.phony: setup
setup: ## run setup scripts to prepare development environment
	@scripts/setup.sh

.phony: build
run: ## run the web server to serve all the slide
	@reveal-md ./

.phony: build
watch: ## start nodemon to watch both reveal-md config and the slide
	@nodemon -w . -e "*" -x "reveal-md ./ --disable-auto-open"
