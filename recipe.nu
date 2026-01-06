# stor import -f "sid_dri_results.html.db"
#
# stor open | query db "select * from requirement"

use ./lib/unit.nu

let state_df = open "state.db"
let usda_df = open "usda.db"

let user_id: int = 1

# wesson vegetable oil 1 al
let id: int = 1106361

let provided = $usda_df
	| query db $"select n.id, n.name, fn.amount, n.unit_name, nrm.requirement as requirement_name
	from food f
	inner join food_nutrient fn
		on fn.fdc_id = f.fdc_id
	inner join nutrient n
		on n.id = fn.nutrient_id
	inner join nutrient_requirement_map nrm
		on nrm.nutrient_id = n.id
	-- most modern units for recent measurements are expressed in terms the metric system
	-- 'special units' like IU or MG_ATE are only a part of datasets like SR_LEGACY
	where n.unit_name like '%G' and
		f.fdc_id = ($id)"
	| update amount {|row| $row.amount | do ($row.unit_name | unit to closure)}
	| rename id name amount_ug
	| reject unit_name
	| inspect

let reqs = $state_df
	| query db $"select
		r.name as requirement_name,
		ur.rec_min,
		ur.rec_max,
		ur.safe_max
	from user_requirement ur
	inner join requirement r
		on r.id = ur.requirement_id
	where ur.user_id = ($user_id)"
	| inspect

$provided | join $reqs requirement_name

