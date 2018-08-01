bootstrap:
	carthage update --platform iOS

refresh:
	cp -R ~/project/TMLPresentation/TMLPresentation/ Carthage/Checkouts/TMLPresentation/TMLPresentation
	rm -rf Carthage/Build/iOS/TMLPresentation.framework*
	carthage build TMLPresentation --platform iOS
