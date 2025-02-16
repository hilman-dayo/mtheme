MAKEFLAGS  := -j 1
INS         = source/beamerthememetropolitoken.ins
PACKAGE_SRC = $(wildcard source/*.dtx)
PACKAGE_STY = $(notdir $(PACKAGE_SRC:%.dtx=%.sty))
DEMO_SRC    = demo/demo.tex demo/demo.bib
DEMO_PDF    = demo/demo.pdf
DOC_SRC     = doc/metropolitokentheme.dtx
DOC_PDF     = doc/metropolitokentheme.pdf

CTAN_CONTENT = README.md $(INS) $(PACKAGE_SRC) $(DOC_SRC) $(DOC_PDF) $(DEMO_SRC) $(DEMO_PDF)

DESTDIR     ?= $(shell kpsewhich -var-value=TEXMFHOME)
INSTALL_DIR  = $(DESTDIR)/tex/latex/metropolitoken
DOC_DIR      = $(DESTDIR)/doc/latex/metropolitoken
CACHE_DIR   := $(shell pwd)/.latex-cache

COMPILE_TEX := latexmk -xelatex -output-directory=$(CACHE_DIR)
export TEXINPUTS:=$(shell pwd):$(shell pwd)/source:${TEXINPUTS}

DOCKER_IMAGE = latex-image
DOCKER_CONTAINER = latex-container

.PHONY: all sty doc demo clean install uninstall ctan clean-cache clean-sty ctan-version docker-run docker-build docker-rm

all: sty doc

sty: $(PACKAGE_STY)

doc: $(DOC_PDF)

demo: $(DEMO_PDF)

clean: clean-cache clean-sty

install: $(PACKAGE_STY) $(DOC_PDF)
	@mkdir -p $(INSTALL_DIR)
	@cp $(PACKAGE_STY) $(INSTALL_DIR)
	@cp logo.jpg $(INSTALL_DIR)
	@mkdir -p $(DOC_DIR)
	@cp $(DOC_PDF) $(DOC_DIR)


# Below was intended for uninstall. For some reasons, it does not work.
# Good for studying...
# @rm -f "$(INSTALL_DIR)/*"
# @rm -f "$(addprefix $(INSTALL_DIR)/, $(PACKAGE_STY))" "$(addprefix $(INSTALL_DIR)/, .DS_Store)"
uninstall:
	@rm -f $(INSTALL_DIR)/*
	@rmdir "$(INSTALL_DIR)"
	@rm -f "$(DOC_DIR)/$(notdir $(DOC_PDF))"
	@rmdir "$(DOC_DIR)"

clean-cache:
	@rm -rf "$(CACHE_DIR)"

clean-sty:
	@rm -f $(PACKAGE_STY)
	@rm -f logo.jpg

ctan: $(CTAN_CONTENT) ctan-version
	@tar --transform "s@\(.*\)@metropolitoken/\1@" -cf metropolitoken-$(shell date "+%Y-%m-%d").tar.gz $(CTAN_CONTENT)

ctan-version:
	@sed -i 's@20[0-9][0-9]/[0-9]*/[0-9]*@$(shell date "+%Y/%m/%d")@' $(PACKAGE_SRC)

$(CACHE_DIR):
	@mkdir -p $(CACHE_DIR)

$(PACKAGE_STY): $(PACKAGE_SRC) $(INS) | clean-cache $(CACHE_DIR)
	@cp source/logo.jpg logo.jpg
	@cd $(dir $(INS)) && latex -output-directory=$(CACHE_DIR) $(notdir $(INS))
	@cp $(addprefix $(CACHE_DIR)/,$(PACKAGE_STY)) .

$(DOC_PDF): $(DOC_SRC) $(PACKAGE_STY) | clean-cache $(CACHE_DIR)
	@cd $(dir $(DOC_SRC)) && $(COMPILE_TEX) $(notdir $(DOC_SRC))
	@cp $(CACHE_DIR)/$(notdir $(DOC_PDF)) $(DOC_PDF)

$(DEMO_PDF): $(DEMO_SRC) $(PACKAGE_STY) | clean-cache $(CACHE_DIR)
	@cd $(dir $(DEMO_SRC)) && $(COMPILE_TEX) $(notdir $(DEMO_SRC))
	@cp $(CACHE_DIR)/$(notdir $(DEMO_PDF)) $(DEMO_PDF)

docker-run: docker-build
	docker run --rm=true --name $(DOCKER_CONTAINER) -i -t -v `pwd`:/data $(DOCKER_IMAGE) make

docker-build:
	docker build -t $(DOCKER_IMAGE) docker

docker-rm:
	docker rm $(DOCKER_CONTAINER)
