.PHONY: generate_tags

local:
	jekyll serve --watch

generate_tags:
	bash generate_tags.sh

build: generate_tags
	jekyll build

upload: build
	aws s3 sync --delete _site/ s3://stathers.net/ --acl public-read --metadata-directive REPLACE --cache-control max-age=300

act:
	act --secret-file .secrets
