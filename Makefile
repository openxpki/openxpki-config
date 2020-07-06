
version:
	touch config.d/system/version.yaml
	sed -r "/^commit:/d" -i config.d/system/version.yaml
	git log -n 1 --format=format:"commit: \"%h\"%n" HEAD > config.d/system/version.yaml
