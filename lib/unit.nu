# micrograms in terms of grams
export def mcg []: oneof<float, int> -> float {
	($in | into float) / 1_000_000
}

# milligrams in terms of grams
export def mg []: oneof<float, int> -> float {
	($in | into float) / 1_000
}

# grams in terms of grams
export def g []: oneof<float, int> -> float {
	into float
}

# kilograms in terms of grams
export def kg []: oneof<float, int> -> float {
	$in * 1000 | into float
}

# converts a unit string to a closure that will convert a given amount in that
# unit string to the corresponding amount in the standard unit (ex. mg -> g)
export def "to closure" []: string -> oneof<closure, nothing> {
	match $in {
		"UG" | "MCG" | "ug" | "mcg" | "microgram" => ({ mcg })
		"MG" | "mg" | "milligram" => ({ mg })
		"G" | "g" | "gram" => ({ g })
		"KG" | "kg" | "kilogram" => ({ kg })
		# we assume we are always dealing with water
		"mcL" | "microliter" => ({ mcg })
		"mL" | "milliliter" => ({ mg })
		"L" | "liter" => ({ g })
		"kL" | "kiloliter" => ({ kg })
	}
}

