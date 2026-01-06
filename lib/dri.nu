# scrape but prompts you for form values with gum
export def "scrape with input" []: nothing -> any {
	let centimeters: float = gum input --placeholder "Height (cm)" | complete | get stdout | into float
	let kilos: float = gum input --placeholder "Weight (kilos)" | complete | get stdout | into float
	let sex = gum choose "Male" "Female"
	let age = gum input --placeholder "Age" | complete | get stdout | into int
	let age_unit = gum choose "yrs" "months"

	let sex_specific = if $sex == "Female" and $age_unit == "yrs" and $age >= 14 {
		{
			pregnant_weeks: (gum input --placeholder "Pregnant Weeks (empty if not applicable)" | complete | get stdout | if $in != "" { $in | into float })
			pre_pregnant_kilos: (gum input --placeholder "Pre-Pregnant Kilos (empty if not applicable)" | complete | get stdout | if $in != "" { $in | into float })
		}
	}

	let activity_level = if $age_unit == "yrs" and $age >= 3 {
		gum choose "Inactive" "Low Active" "Active" "Very Active"
	} else { "" }

	scrape --sex $sex --age $age --age-unit $age_unit --pregnant-weeks $sex_specific.pregnant_weeks? --pre-pregnant-kilos $sex_specific.pregnant_kilos? --cm $centimeters --kilos $kilos --activity-level $activity_level
}

# calls NAL's DRI calculator
# https://www.nal.usda.gov/human-nutrition-and-food-safety/dri-calculator/
export def scrape [
	--sex: string
	--age: int
	--age-unit: string
	--pregnant-weeks: oneof<float, int>
	--pre-pregnant-pounds: oneof<float, int>
	--pre-pregnant-kilos: oneof<float, int>
	--feet: oneof<float, int>
	--inches: oneof<float, int>
	--cm: oneof<float, int>
	--pounds: oneof<float, int>
	--kilos: oneof<float, int>
	# one of: "Inactive", "Low Active", "Active", "Very Active"
	--activity-level: string
]: nothing -> any {
	let form_build_id = http get "https://www.nal.usda.gov/human-nutrition-and-food-safety/dri-calculator"
		| query web --query "form#dri-calculator-form input[name='form_build_id']" --attribute value
		| first

	let body = {
		measurement_units: std
		sex: $sex
		age_value: ($age | into string)
		age_type: ($age_unit | default "yrs")
		pregnant_weeks: ($pregnant_weeks | default "" | into string)
		pre_pregnant_pounds: ($pre_pregnant_pounds | default "" | into string)
		pre_pregnant_kilos: ($pre_pregnant_kilos | default "" | into string)
		feet: ($feet | default "" | into string)
		inches: ($inches | default "" | into string)
		cm: ($cm | default "" | into string)
		pounds: ($pounds | default "" | into string)
		kilos: ($kilos | default "" | into string)
		activity_level: $activity_level
		op: "Submit"
		form_build_id: $form_build_id
		form_id: "dri_calculator_form"
	} | url build-query
	let headers = {
		"Content-Type": "application/x-www-form-urlencoded"
	}

	let cookie = http post "https://www.nal.usda.gov/human-nutrition-and-food-safety/dri-calculator" $body --headers $headers --full --redirect-mode manual
		| get headers.response
		| where name == "set-cookie"
		| first
		| get value

	http get "https://www.nal.usda.gov/human-nutrition-and-food-safety/dri-calculator/results" --headers {
		host: "www.nal.usda.gov"
		referer: "https://www.nal.usda.gov/human-nutrition-and-food-safety/dri-calculator"
		cookie: $cookie
	}
}

def "error make parse-fail" [text: string, msg: string]: nothing -> error {
	error make {
		msg: $"($msg): '($text)'",
		help: "Review the parsing logic."
	}
}

def parse-bounds []: string -> oneof<record<single: oneof<float, nothing>, pair: oneof<record<left: float, right: float>, nothing>, unit: string>, nothing> {
	let text = $in

	let units = $text | parse --regex `(\s|^)(?<unit>microliter|milliliter|liter|kiloliter|kilogram|gram|milligram|microgram|kg|g|mg|mcg|mcL|mL|L|kL)(\s|s|$)`
	if ($units | length) > 1 {
		error make parse-fail $text "Unknown units"
	}

	let pair = $text | parse --regex `(?<left>\d+[\.]?\d+) *- *(?<right>\d+[\.]?\d+)`
	if ($pair | length) == 1 {
		if ($units | is-empty) {
			error make parse-fail $text "No units"
		}
		return {
			pair: {
				left: ($pair.left | first)
				right: ($pair.right | first)
			}
			unit: ($units.unit | first)
		}
	} else if ($pair | length) > 0 {
		error make parse-fail $text "Got more than one range in text"
	}

	let numbers = $text | parse --regex `(?<num>\d*[\.]?\d+)`
	if ($numbers | is-empty) and ($units.unit | is-empty) {
		return null
	}
	if ($units | is-empty) {
		error make parse-fail $text "No units"
	}
	if ($numbers | is-empty) {
		error make parse-fail $text "No numbers"
	}

	return {
		single: ($numbers.num | first)
		unit: ($units.unit | first)
	}
}

def normalize-units []: oneof<record<single: oneof<float, nothing>, pair: oneof<record<left: float, right: float>, nothing>, unit: string>, nothing> -> oneof<record<single: oneof<float, nothing>, pair: oneof<record<left: float, right: float>, nothing>>, nothing> {
	let entry = $in
	if ($entry == null) {
		return null
	}
	let unit_fn = $entry.unit | unit to closure
	if "single" in ($entry | columns) {
		return {single: ($entry.single | into float | do $unit_fn)}
	}
	return {pair: {
		left: ($entry.pair.left | into float | do $unit_fn)
		right: ($entry.pair.right | into float | do $unit_fn)
	}}
}

def parse-table []: oneof<table<name: string, rec: string>, table<name: string, rec: string, ul: oneof<string, nothing>>> -> table<name: string, rec_min: oneof<float, nothing>, rec_max: oneof<float, nothing>, safe_max: oneof<float, nothing>> {
	each {|row|
		let rec_value = $row.rec | parse-bounds
		if $rec_value == null {
			return null
		}
		let rec_value = $rec_value | normalize-units

		let ul_value = $row.ul? | default "" | parse-bounds
		let safe_max = if $ul_value != null {
			let ul_value = $ul_value | normalize-units
			if not ("single" in ($ul_value | columns)) {
				error make {
					msg: "Upper limit has a paired value.",
				}
			}
			$ul_value.single
		} else { null }

		if "single" in ($rec_value | columns) {
			{
				name: $row.name
				rec_min: $rec_value.single
				rec_max: null
				safe_max: $safe_max
			}
		} else {
			{
				name: $row.name
				rec_min: $rec_value.pair.left
				rec_max: $rec_value.pair.right
				safe_max: $safe_max
			}
		}
	}
}

# parses the results of 'scrape'
export def "parse results" []: any -> table<name: string, category: string, rec_min: float, rec_max: oneof<float,nothing>, safe_max: oneof<float,nothing>> {
	let macronutrients = $in
		| query web --as-table ["Macronutrient" "Recommended Intake Per Day"]
		| rename name rec
		| parse-table
		| insert category "Macronutrient"

	let vitamins = $in
		| query web --as-table ["Vitamin" "Recommended Intake Per Day" "Tolerable UL Intake Per Day"]
		| rename name rec ul
		| parse-table
		| insert category "Vitamin"

	let minerals = $in
		| query web --as-table ["Mineral" "Recommended Intake Per Day" "Tolerable UL Intake Per Day"]
		| flatten
		| rename name rec ul
		| parse-table
		| insert category "Mineral"

	[...$macronutrients ...$vitamins ...$minerals]
}

