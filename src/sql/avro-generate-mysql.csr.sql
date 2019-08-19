select 
concat('{"schema":','"{','|"type|":|"record|",|"name|":|"',@srv,'_',table_schema,'_',table_name,'|",|"fields|":[') 
as avro_schema
from information_schema.tables where table_schema=@db and table_name=@table
union
select concat(c1.a,c1.b)
from
(select concat('{|"name|":|"',column_name,'|",|"type|":') as a,
case
when data_type in ('char','varchar','date','text','enum') and is_nullable='NO' then '|"string|"},'
when data_type in ('char','varchar','date','text','enum') and is_nullable='YES' then '[|"null|",|"string|"]},'
when data_type in ('smallint','mediumint','int') and is_nullable='NO' then '|"int|"},'
when data_type in ('smallint','mediumint','int') and is_nullable='YES' then '[|"null|",|"int|"]},'
when data_type in ('tinyint') and is_nullable='NO' then '|"boolean|"},'
when data_type in ('tinyint') and is_nullable='YES' then '[|"null|",|"boolean|"]},'
when data_type in ('bigint') and is_nullable='NO' then '|"long|"},'
when data_type in ('bigint') and is_nullable='YES' then '[|"null|",|"long|"]},'
when data_type in ('double') and is_nullable='NO' then '|"double|"},'
when data_type in ('double') and is_nullable='YES' then '[|"null|",|"double|"]},'
else concat('|"',data_type,'|"},') end as b
from information_schema.columns where table_schema=@db and table_name=@table) c1
union select ']}"}';

