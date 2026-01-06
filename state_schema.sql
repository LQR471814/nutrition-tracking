create table user (
	id integer primary key autoincrement,
	name text not null unique
);

create table requirement (
	id integer primary key autoincrement,
	category text not null,
	name text not null unique
);

create table user_requirement (
	user_id integer not null references user(id)
		on delete cascade
		on update cascade,
	requirement_id integer not null references requirement(id)
		on delete cascade
		on update cascade,
	-- in g
	rec_min real not null,
	-- in g
	rec_max real,
	-- in g
	safe_max real,
	primary key (user_id, requirement_id)
);

create table recipe (
	id integer primary key autoincrement,
	name text not null unique,
	comment text
);

create table recipe_usda_food_contrib (
	recipe_id integer not null references recipe(id)
		on delete cascade
		on update cascade,
	usda_fdc_id integer not null,
	-- amount (g)
	amount real not null
);

create table recipe_contrib (
	recipe_id integer not null references recipe(id)
		on delete cascade
		on update cascade,
	requirement_id integer not null references requirement(id)
		on delete cascade
		on update cascade,
	-- amount (g)
	amount real not null
);

create table user_consumption (
	user_id integer not null references user(id)
		on delete cascade
		on update cascade,
	recipe_id integer not null references requirement(id)
		on delete cascade
		on update cascade,
	comment text,
	amount real not null,
	time datetime not null
);

