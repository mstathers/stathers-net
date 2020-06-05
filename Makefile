AWS_PROFILE:=default
local:
	jekyll serve --watch

build:
	jekyll build

upload: build
	aws s3 cp _site/ s3://stathers.net/ --recursive
