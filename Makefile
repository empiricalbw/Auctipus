.PHONY: test
test:
	luac5.1 -p *.lua
	xmllint --noout --schema /Applications/World\ of\ Warcraft/_classic_/BlizzardInterfaceCode/Interface/FrameXML/UI.xsd *.xml
