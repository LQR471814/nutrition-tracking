use ./lib/dri.nu

dri scrape --sex male --age 19 --feet 5 --inches 10 --pounds 114.5 --activity-level "Inactive"
	| save "profile_1_sid.html"
