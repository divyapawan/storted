

CREATE proc [perform].[pr_capad_finacle_undrawn] (@mstart_date datetime)    

as    

SET NOCOUNT ON    

/*    

Created By : Mustafa Pehlari    

Created On : 28-Dec-2009    

Reason  : CRPER21962: Computation of Capital Adequancy (CAPAD) reports  

  

*/    

    

begin    

    

--declare @mstart_date datetime    

--set @mstart_date='31-dec-08'    

  

--used perform_arch_backup..rating_table  instead of perform_backup2..rating_table r   on 11-Feb-2014 By Subhash Chandra

    

select ucc customer_code, consol_rating, rank     

into #internal_rating    

from perform_backup2..rating_table rmast    

inner join     

(    

 select equivalent_rating, rank from pf_rating_map --where rank in (1,2)    

 group by equivalent_rating, rank    

)rmap     

on rmast.consol_rating = rmap.equivalent_rating    

where mon_yr = @mstart_date    

and CONVERT(BIGINT,REPLACE(ucc,'DWH','')) > 0    

order by 1    

    



end 

SET NOCOUNT OFF