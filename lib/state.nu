def "import requirements" [db: any, user_id: int]: table<name: string, category: string, rec_min: float, rec_max: oneof<float,nothing>, safe_max: oneof<float,nothing>> -> nothing {
	let rows = $in

	let requirement_values = $rows
		| each {|row| $"\('($row.category)', '($row.name)'\)"}
		| str join ",\n"
	let requirement_ids = $db
		| query db $"insert into requirement \(category, name\)
values ($requirement_values)
on conflict do update
	set category = excluded.category
returning id"
		| get id

	let user_requirement_values = $rows
		| zip $requirement_ids
		| each {|zipped|
			let row = $zipped.0
			let requirement_id = $zipped.1
			$"\(($user_id), ($requirement_id), ($row.rec_min), ($row.rec_max | default "null"), ($row.safe_max | default "null")\)"
		}
		| str join ",\n"
	$db
		| query db $"insert into user_requirement \(user_id, requirement_id, rec_min, rec_max, safe_max\)
values ($user_requirement_values)
on conflict do update
	set rec_min = excluded.rec_min,
		rec_max = excluded.rec_max,
		safe_max = excluded.safe_max"
}

# create user creates a new user in the state db
#
#  - it takes a list of requirements as input
export def "create user" [db: any, user_id: int, name: string]: table<name: string, category: string, rec_min: float, rec_max: oneof<float,nothing>, safe_max: oneof<float,nothing>> -> nothing {
	let input = $in

	$db | query db $"insert into user \(id, name\)
	values \(($user_id), '($name)'\)
	on conflict do update
		set name = excluded.name"

	$input | import requirements $db $user_id

	$db
		| query db "select * from requirement"
		| print

	$db
		| query db "select * from user_requirement"
		| print
}

