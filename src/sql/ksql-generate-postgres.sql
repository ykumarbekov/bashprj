select c1.ksql_table
from
(select '1' as id,concat('create stream str_',:v1,'_',:v2,'_',:v3,' (') as ksql_table
from information_schema.tables where table_name=:v3
union
select '2',c.b from
(select 
case
when data_type in ('char','varchar','date','text','enum','time','timestamp','character') then concat(column_name,' string,')
when data_type in ('smallint','int','serial','integer') then concat(column_name,' integer,')
when data_type in ('boolean') then concat(column_name,' boolean,')
when data_type in ('bigint') then concat(column_name,' bigint,')
when data_type in ('double','real','numeric') then concat(column_name,' double,')
else concat(column_name,' string,') end as b
from information_schema.columns where  table_name=:v3)c
union 
select b.id,b.m1 
from 
(select 
'3' as id,
case when kcu.column_name is not null then
concat(') with (kafka_topic=','"',:v1,'_',:v2,'_',:v3,'",','value_format="json",','key="',kcu.column_name,'");')
else 
concat(') with (kafka_topic=','"',:v1,'_',:v2,'_',:v3,'",','value_format="json");')
end as m1
from information_schema.tables t
        left join information_schema.table_constraints tc
                 on tc.table_catalog = t.table_catalog
                 and tc.table_schema = t.table_schema
                 and tc.table_name = t.table_name
                 and tc.constraint_type = 'PRIMARY KEY'
        left join information_schema.key_column_usage kcu
                 on kcu.table_catalog = tc.table_catalog
                 and kcu.table_schema = tc.table_schema
                 and kcu.table_name = tc.table_name
                 and kcu.constraint_name = tc.constraint_name
where t.table_name=:v3 limit 1)b)c1 order by c1.id;
