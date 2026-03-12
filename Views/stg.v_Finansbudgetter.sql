create view stg.v_Finansbudgetter as
  select distinct Budget_Name, Company from stg.Finansbudgetter
GO
