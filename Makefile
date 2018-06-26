BUILD_DIR=build
P4_SOURCES_DIR=scenarios
SEARCH_PATH=$(P4_SOURCES_DIR)/headers
TARGET=bmv2
ARCH=v1model

define add_scenario_rule
scenario-$(1):
	$(eval SOURCES_DIR=$(P4_SOURCES_DIR)/$(1))
	$(eval WORKING_DIR=$(BUILD_DIR)/$(1))
	$(eval SOURCES=$(SOURCES_DIR)/$(1).p4)
	$(eval GRAPHS_DIR=$(WORKING_DIR)/graphs)

	p4c --target $(TARGET) --arch $(ARCH) -I $(SEARCH_PATH) \
		-o $(WORKING_DIR) $(SOURCES)

	mkdir -p $(GRAPHS_DIR)
	p4c-graphs -I $(SEARCH_PATH) --graphs-dir $(GRAPHS_DIR) $(SOURCES)
	for file in `ls $(GRAPHS_DIR)/*.dot`; do \
		dot -Tpng "$$$$file" > "$$$${file%.dot}.png"; \
	done
	rm -rf $(GRAPHS_DIR)/*.dot
endef

$(eval $(call add_scenario_rule,l2sw))

create-env:
	mkdir -p ${BUILD_DIR}

all: create-env scenario-l2sw

clean:
	rm -rf ${BUILD_DIR}
