bootstrap:
	carthage update --platform iOS

refresh:
	cp -R ~/project/TMLPresentation/TMLPresentation/ Carthage/Checkouts/TMLPresentation/TMLPresentation
	carthage build TMLPresentation --platform iOS
