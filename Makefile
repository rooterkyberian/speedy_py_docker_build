.PHONY: build_all

define build
    docker build -f $(1).Dockerfile . -t speedy-$(1)
endef

build_all:
	$(call build,0-simple)
	$(call build,1-cached)
	$(call build,2-alpine)
	$(call build,3-slim)
