AWS_PROFILE:=default
local:
	jekyll serve --watch

build:
	jekyll build

upload: build
	aws s3 sync --delete _site/ s3://stathers.net/ --acl public-read --metadata-directive REPLACE --cache-control max-age=300
#	aws s3 cp --recursive s3://stathers.net/ s3://stathers.net/ --metadata-directive REPLACE --cache-control max-age=300
