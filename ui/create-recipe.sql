-- navbar
select
       'breadcrumb' as component;
select
       'Home' as title,
       '/'    as link;
select
       'Create Recipe' as title,
       '/create-recipe'    as link;

select
	'form' as component,
	'Create New Recipe' as title,
	"Reset" as reset
select
	'name' as name,
	'Name' as label,
	true as required,
	'text' as type;
select
	'comment' as name,
	'Comments' as label,
	'textarea' as type;
insert into recipe (name, comment)
select :name, :comment
where :name is not null;

