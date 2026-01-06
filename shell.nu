use ./lib/dri.nu
use ./lib/state.nu
use ./lib/unit.nu

let state_db = open "state.db"
let usda_db = open "usda.db"

def "create user" [name: string, --id: int]: nothing -> nothing {
	dri scrape with input
		| dri parse results
		| state create user $state_db $id $name
}

def "find food" [query: string]: nothing -> any {
	$usda_db
		| query db $"select * from food f
		where f.description like '($query | str replace -a "*" "%")'"
		| each {|row| $"($row.description)|($row.data_type)|($row.food_category_id)|($row.publication_date)|($row.fdc_id)"}
		| str join "\n"
		| column -t -s "|"
		| fzf
		| complete
		| get stdout | into string | parse -r `(?m)(?<id>\d+)$`
		| get 0.id | into int
}

def "find user" []: nothing -> int {
	$state_db
		| query db "select * from user"
		| each {|row| $"($row.name)|($row.id)"}
		| str join "\n"
		| column -t -s "|"
		| fzf
		| complete
		| get stdout | into string | parse -r `(?m)(?<id>\d+)$`
		| get 0.id | into int
}

def "find recipe" []: nothing -> int {
	$state_db
		| query db "select * from recipe"
		| each {|row| $"($row.name)|($row.id)"}
		| str join "\n"
		| column -t -s "|"
		| fzf
		| complete
		| get stdout | into string | parse -r `(?m)(?<id>\d+)$`
		| get 0.id | into int
}

def "add consumption" [user_id: int, recipe_id: int, amount: float, --comment: string] {
	let comment_value = if $comment != null { $"'($comment)'" } else { "NULL" }
	let now = date now | format date "%Y-%m-%d %H:%M:%S"
	$state_db
		| query db $"insert into user_consumption \(user_id, recipe_id, comment, time, amount\)
		values \(($user_id), ($recipe_id), ($comment_value), '($now)', ($amount)\)"
	null
}

def progress [user_id: int] {
	let start_of_today = date now | format date "%Y-%m-%d" | into datetime
	let start_of_tomorrow = (date now) + 1day | format date "%Y-%m-%d" | into datetime

	# 1. get recipes user consumed
	# 2. each recipe has raw contributions & USDA contributions
	# 3. sum of gram weight of all contributions = recipe total weight
	# 4. scale all contributions by actual amount of recipe user has consumed
	# 5. sum up all contributions for all recipes user has consumed

	# 2.
	let today_contrib: table = $state_db
		| query db $"select
			rc.requirement_id,
			rc.amount as recipe_contrib_amount,
			uc.amount as user_consumed_amount
		from user_consumption uc
		inner join recipe_contrib rc
			on uc.recipe_id = rc.recipe_id
		where uc.time >= '($start_of_today)' and uc.time < '($start_of_tomorrow)'"

	# 3.
	let today_contrib_foods_usda: table = $state_db
		| query db $"select
			rc.usda_fdc_id as fdc_id,
			rc.amount as food_contrib_amount,
			uc.amount as user_consumed_amount
		from user_consumption uc
		inner join recipe_usda_food_contrib rc
			on uc.recipe_id = rc.recipe_id"

	let fdc_ids = $today_contrib_foods_usda
		| each {|row| $row.fdc_id | into string}
		| str join ","

	let usda_food_contribs: table<amount: float, nutrient_id: int> = $usda_db
		# nutrient_id is a USDA nutrient_id
		| query db $"select
			fn.amount,
			fn.nutrient_id,
			fn.fdc_id,
			n.unit_name
		from food_nutrient fn
		inner join nutrient n
			on n.id = fn.nutrient_id
		where fn.fdc_id in \(($fdc_ids)\)"
		| group-by --to-table fdc_id # group by foods
		| enumerate
		| each {|it| # for a particular food
			let food_rows = $it.item.items
			# sum is the total weight of the food
			let sum = $food_rows | reduce -f 0 {|it,acc| $acc + $it.amount }
			# food_contrib_amount is the amount of the food present in the recipe
			let contrib = $today_contrib_foods_usda
				| get $it.index
			let food_contrib_amount = $contrib
				| get food_contrib_amount
			# table<amount: float, nutrient_id: int, user_consumed_amount: float>
			# where:
			# - 'amount' is the amount (g) of a particular nutrient in the resulting recipe
			# - 'nutrient_id' is the corresponding USDA nutrient id
			# - 'user_consumed_amount' is the amount
			$food_rows
				| update amount {|row|
					# if unit conversion closure doesn't exist, it means the
					# unit is not for mass and we can simply ignore the
					# contribution
					let to_ug = $row.unit_name | unit to closure | default { ({ 0 }) }
					let amount_g = $row.amount | do $to_ug
					$amount_g / $sum * $food_contrib_amount
				}
				| insert user_consumed_amount $contrib.user_consumed_amount
				| reject fdc_id
		}
		| flatten
		| group-by --to-table nutrient_id
		| each {|group| # sum the nutrient contributions found in all linked USDA foods
			let sum = $group.items | reduce -f 0 {|it,acc| $acc + $it.amount}
			{
				usda_amount: $sum
				nutrient_id: $group.items.0.nutrient_id
				user_consumed_amount: $group.items.0.user_consumed_amount
			}
		}
		# link USDA nutrient ids to state nutrient requirement ids
		| join ($usda_db | query db "select * from nutrient_requirement_map") nutrient_id
		| join ($state_db | query db "select
			id as requirement_id,
			name as requirement
		from requirement") requirement
		| select usda_amount requirement_id user_consumed_amount

	# 4.
	let total_raw_contrib_weight = $today_contrib | reduce -f 0 {|it,acc| $acc + $it.recipe_contrib_amount}
	let total_usda_contrib_weight = $usda_food_contribs | reduce -f 0 {|it,acc| $acc + $it.usda_amount}
	let total_recipe_weight = $total_raw_contrib_weight + $total_usda_contrib_weight

	let today_contrib: table<requirement_id: int, recipe_contrib_amount: float> = $today_contrib
		| update recipe_contrib_amount {|row|
			$row.recipe_contrib_amount / $total_recipe_weight * $row.user_consumed_amount
		}
	let usda_food_contribs: table<requirement_id: int, usda_amount: float> = $usda_food_contribs
		| update usda_amount {|row|
			$row.usda_amount / $total_recipe_weight * $row.user_consumed_amount
		}

	# 5.
	$state_db
		| query db "select
			ur.requirement_id,
			r.name,
			ur.rec_min,
			ur.rec_max,
			ur.safe_max
		from user_requirement ur
		inner join requirement r
			on r.id = ur.requirement_id"
		| join -l $today_contrib requirement_id
		| join -l $usda_food_contribs requirement_id
		| each {|row|
			{
				requirement: $row.name
				progress: (($row.recipe_contrib_amount? | default 0) + ($row.usda_amount? | default 0))
				rec_min: $row.rec_min
				rec_max: $row.rec_max
				safe_max: $row.safe_max
			}
		}
}

[
	[command description];
	["create user" "Create a new user"]
	["find food" "Find a USDA fdc_id"]
	["find user" "Find a user id"]
	["find recipe" "Find a recipe id"]
	["add consumption" "Add a user consumption entry"]
	["progress" "Analyze daily progress of users"]
] | print

