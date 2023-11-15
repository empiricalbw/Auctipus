.PHONY: test
test:
	luac5.1 -p *.lua
	xmllint --noout --schema /Applications/World\ of\ Warcraft/_classic_era_/BlizzardInterfaceCode/Interface/FrameXML/UI_shared.xsd *.xml
