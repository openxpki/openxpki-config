
version:
	touch config.d/system/version.yaml
	sed -r "/^commit:/d" -i config.d/system/version.yaml
	git log -n 1 --format=format:"commit: \"%h\"%n" HEAD > config.d/system/version.yaml

contrib/i18n/openxpki-config.i18n: config.d template
	@grep -rhoEe 'I18N_OPENXPKI_UI_\w+' config.d template | sort | uniq > contrib/i18n/openxpki-config.i18n

