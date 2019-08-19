select c1.avro_schema
from
(select '1' as id,concat('{"schema":','"{','|"type|":|"record|",|"name|":|"',:v1,'_',:v2,'_',:v3,'|",|"fields|":[') as avro_schema
from information_schema.tables where table_name=:v3
union
select '2',concat(c.a,c.b) from
(select 
concat('{|"name|":|"',column_name,'|",|"type|":') as a,
case
when data_type in ('char','varchar','date','text','enum','time','timestamp','character') and is_nullable='NO' then '|"string|"},'
when data_type in ('char','varchar','date','text','enum','time','timestamp','character') and is_nullable='YES' then '[|"null|",|"string|"]},'
when data_type in ('smallint','int','serial','integer') and is_nullable='NO' then '|"int|"},'
when data_type in ('smallint','int','serial','integer') and is_nullable='YES' then '[|"null|",|"int|"]},'
when data_type in ('boolean') and is_nullable='NO' then '|"boolean|"},'
when data_type in ('boolean') and is_nullable='YES' then '[|"null|",|"boolean|"]},'
when data_type in ('bigint') and is_nullable='NO' then '|"long|"},'
when data_type in ('bigint') and is_nullable='YES' then '[|"null|",|"long|"]},'
when data_type in ('double','real','numeric') and is_nullable='NO' then '|"double|"},'
when data_type in ('double','real','numeric') and is_nullable='YES' then '[|"null|",|"double|"]},'
else concat('|"',data_type,'|"},') end as b
from information_schema.columns where  table_name=:v3)c
union select '3',']}"}')c1 order by c1.id;
