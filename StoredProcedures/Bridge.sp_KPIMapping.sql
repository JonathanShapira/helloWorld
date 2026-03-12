CREATE procedure [Bridge].[sp_KPIMapping] as
begin
drop table if exists switch.Bridge_KPIMapping;
select coalesce(Acc.Accounts_key,-1) as Accounts_key,coalesce(Res.ResultatLayout_key,-1) as ResultatLayout_key,coalesce(Bal.BalanceLayout_key,-1) as BalanceLayout_key,coalesce(Cash.CashflowLayout_key,-1) as CashflowLayout_key
into switch.Bridge_KPIMapping
from stg.KPIMapping Map
left join dim.ResultatLayout Res on Res.KPI = Map.KPI
left join dim.BalanceLayout Bal on Bal.KPI = Map.KPI
left join dim.CashflowLayout Cash on Cash.KPI = Map.KPI
left join dim.Accounts Acc on Acc.Company = Map.Virksomhed and Convert(int,Acc.No) >= Convert(int,Map.Fra) and Convert(int,Acc.No) <= Convert(int,Map.Til)
;
/*
drop table if exists bridge.KPIMapping
select * into bridge.KPIMapping from switch.Bridge_KPIMapping
*/

exec utility.SwitchTableProcedure
@Switch_Schema = 'switch'
,@switch_table_name='Bridge_KPIMapping'
,@Target_Schema='bridge'
,@Target_Table_Name = 'KPIMapping'
,@force_switch = 1
,@accepted_pct = 0
end;

GO
