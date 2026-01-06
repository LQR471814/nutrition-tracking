# taken from the NAL's dri-calculator:
# https://www.nal.usda.gov/human-nutrition-and-food-safety/dri-calculator/

use ./lib/state.nu
use ./lib/dri.nu

let state_db = open "state.db"

ls profile_*.html
	| each {|profile|
		let prof = $profile.name
			| parse --regex `profile_(?<id>\d)_(?<name>.+)\.html`
			| first
		let user_id = $prof.id | into int
		open $profile.name
			| dri parse results
			| state create user $state_db $user_id $prof.name
	}

null

