-- navbar
select
       'breadcrumb' as component;
select
       'Home' as title,
       '/'    as link;

-- user select
select 'title' as component,
       'Users' as contents;
select
       'list' as component,
       true as compact;
select
       name as title,
       '/user?id=' || id as link
from user;

-- recipes
select 'title' as component,
       'Recipes' as contents;
select
       'table'          as component,
       TRUE             as sort,
       TRUE             as search,
       'Search' as search_placeholder,
       'Name' as markdown;
select
       '[' || name || '](/recipe?id=' || id || ')' as Name,
       comment as Comments
from recipe;

select 'button' as component;
select '/create-recipe' as link,
       'Create Recipe' as title,
       'info' as color;
