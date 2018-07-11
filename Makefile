BUILD_DIR=build
P4_SOURCES_DIR=scenarios
SEARCH_PATH=$(P4_SOURCES_DIR)/headers
TARGET=bmv2
ARCH=v1model

define add_scenario_rules
scenario-$(1):
	$(eval SOURCES_DIR=$(P4_SOURCES_DIR)/$(1))
	$(eval WORKING_DIR=$(SOURCES_DIR)/$(BUILD_DIR)/)
	$(eval SOURCES=$(SOURCES_DIR)/$(1).p4)
	$(eval GRAPHS_DIR=$(WORKING_DIR)/graphs)

	mkdir -p $(WORKING_DIR)
	p4c --target $(TARGET) --arch $(ARCH) -I $(SEARCH_PATH) \
		-o $(WORKING_DIR) $(SOURCES)

scenario-$(1)-graphs:
	mkdir -p $(GRAPHS_DIR)
	p4c-graphs -I $(SEARCH_PATH) --graphs-dir $(GRAPHS_DIR) $(SOURCES)
	for file in `ls $(GRAPHS_DIR)/*.dot`; do \
		dot -Tpng "$$$$file" > "$$$${file%.dot}.png"; \
	done
	rm -rf $(GRAPHS_DIR)/*.dot

scenario-$(1)-clean:
	rm -rf $(WORKING_DIR)
endef

$(eval $(call add_scenario_rules,l2sw))
$(eval $(call add_scenario_rules,l2sw-vlan))

all: scenario-l2sw scenario-l2sw-vlan

test:
	./run_tests.sh

graphs: scenario-l2sw-graphs scenario-l2sw-vlan-graphs

clean: scenario-l2sw-clean scenario-l2sw-vlan-clean

.DEFAULT_GOAL := all
