-- navbar
select
       'breadcrumb' as component;
select
       'Home' as title,
       '/'    as link;
select
       (select name from recipe where id = $id) as title,
       '/recipe?id=' || $id as link;

select
	'form' as component,
	'Edit Recipe' as title
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

