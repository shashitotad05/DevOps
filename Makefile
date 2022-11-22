########################################################################################################################
#
#
########################################################################################################################
.DEFAULT_GOAL := help

# Execute everything on same shell, so the active of the virtualenv works on the next command
#.ONESHELL:

.PHONY: install

#SHELL=./make-venv

# include *.mk

_venv: _venv/touchfile
	
_venv/touchfile: requirements.txt
	test -d venv || virtualenv venv --python=python3
	. venv/bin/activate && python -m pip install -Ur requirements.txt
	touch venv/touchfile

clean: ## clean
	rm -rf venv

# TODO: make dynamic
theme = edx-platform/nau-basic
COMPOSE_PROJECT_NAME= nau-juniper-devstack

# TODO: define somewhere else
lang_targets = en pt_PT

create_translations_catalogs: _venv | extract_translations
	for lang in $(lang_targets) ; do \
        . venv/bin/activate && pybabel init -i $(theme)/conf/locale/django.pot -D django -d $(theme)/conf/locale/ -l $$lang ; \
		. venv/bin/activate && pybabel init -i $(theme)/conf/locale/djangojs.pot -D djangojs -d $(theme)/conf/locale/ -l $$lang ; \
    done

extract_translations: _venv
	. venv/bin/activate && pybabel extract -F $(theme)/conf/locale/babel_mako.cfg -o $(theme)/conf/locale/django.pot --msgid-bugs-address=ajuda@nau.edu.pt --copyright-holder=FCT-FCCN -c Translators $(theme)/*
	. venv/bin/activate && pybabel extract -F $(theme)/conf/locale/babel_underscore.cfg -o $(theme)/conf/locale/djangojs.pot --msgid-bugs-address=ajuda@nau.edu.pt --copyright-holder=FCT-FCCN -c Translators $(theme)/*

update_translations: _venv| extract_translations update_translations_po_files clean_translations_intermediate compile_translations ## update strings to be translated

clean_translations_intermediate:
	rm -f $(theme)/conf/locale/django.pot
	rm -f $(theme)/conf/locale/djangojs.pot

update_translations_po_files: _venv
	. venv/bin/activate && pybabel update -N -D django -i $(theme)/conf/locale/django.pot -d $(theme)/conf/locale/
	. venv/bin/activate && pybabel update -N -D djangojs -i $(theme)/conf/locale/djangojs.pot -d $(theme)/conf/locale/

compile_translations: _venv
	. venv/bin/activate && pybabel compile -f -D django -d $(theme)/conf/locale/
	. venv/bin/activate && pybabel compile -f -D djangojs -d $(theme)/conf/locale/

publish_lms_devstack: | update_translations ## Publish changes to LMS devstack
	@echo "Running compilejsi18n && collectstatic at lms"
	@docker exec -t edx.$(COMPOSE_PROJECT_NAME).lms bash -c 'source /edx/app/edxapp/edxapp_env && cd /edx/app/edxapp/edx-platform/ && python manage.py lms compilejsi18n --locale pt-pt'
	@docker exec -t edx.$(COMPOSE_PROJECT_NAME).lms bash -c 'source /edx/app/edxapp/edxapp_env && cd /edx/app/edxapp/edx-platform/ && python manage.py lms compilejsi18n --locale en'
	@docker exec -t edx.$(COMPOSE_PROJECT_NAME).lms bash -c 'source /edx/app/edxapp/edxapp_env && cd /edx/app/edxapp/edx-platform/ && python manage.py lms collectstatic -i *css -i templates -i vendor --noinput -v2 | grep Copying | grep i18n'
	@docker exec -t edx.$(COMPOSE_PROJECT_NAME).lms bash -c 'kill $$(ps aux | grep "manage.py lms" | egrep -v "while|grep" | awk "{print \$$2}")'

publish_studio_devstack: | update_translations ## Publish changes to STUDIO devstack
	@echo "Running compilejsi18n && collectstatic at studio"
	@docker exec -t edx.$(COMPOSE_PROJECT_NAME).studio bash -c 'source /edx/app/edxapp/edxapp_env && cd /edx/app/edxapp/edx-platform/ && python manage.py cms compilejsi18n --locale pt-pt'
	@docker exec -t edx.$(COMPOSE_PROJECT_NAME).studio bash -c 'source /edx/app/edxapp/edxapp_env && cd /edx/app/edxapp/edx-platform/ && python manage.py cms compilejsi18n --locale en'
	@docker exec -t edx.$(COMPOSE_PROJECT_NAME).studio bash -c 'source /edx/app/edxapp/edxapp_env && cd /edx/app/edxapp/edx-platform/ && python manage.py cms collectstatic -i *css -i templates -i vendor --noinput -v2 | grep Copying | grep i18n'
	@docker exec -t edx.$(COMPOSE_PROJECT_NAME).studio bash -c 'kill $$(ps aux | grep "manage.py cms" | egrep -v "while|grep" | awk "{print \$$2}")'

# Generates a help message. Borrowed from https://github.com/pydanny/cookiecutter-djangopackage.
help: ## Display this help message
	@echo "Please use \`make <target>' where <target> is one of"
	@perl -nle'print $& if m{^[\.a-zA-Z_-]+:.*?## .*$$}' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m  %-25s\033[0m %s\n", $$1, $$2}'
