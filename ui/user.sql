-- navbar
select
    'breadcrumb' as component;
select
    'Home' as title,
    '/'    as link;
select
    (select name from user where id = $id) as title,
    '/user/?id=' || $id as link;

