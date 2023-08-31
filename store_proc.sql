

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

    

    

    

create table #temp    

(    

 sbu varchar(100),    

 ucc varchar(255),    

 cname varchar(100),    

 consol_rating varchar(10),    

 INDUSTRY VARCHAR(25),    

 SOURCE_FLAG VARCHAR(25),    

    

 MARGIN_AMOUNT_UCC DECIMAL(21,4),    

    

 GROSS_OUTSTANDING DECIMAL(21,4),    

 CCF DECIMAL(21,4),    

 GROSS_CCF DECIMAL(21,4),    

 NET_OUTSTANDING DECIMAL(21,4),    

    

 CRE_GROSS DECIMAL(21,4),    

 CRE_CCF DECIMAL(21,4),    

 CME_GROSS DECIMAL(21,4),    

 CME_CCF DECIMAL(21,4),    

 NBFC_GROSS DECIMAL(21,4),    

 NBFC_CCF DECIMAL(21,4),    

 NPA_GROSS DECIMAL(21,4),    

 NPA_CCF DECIMAL(21,4),    

 RESTRUCTURED_GROSS DECIMAL(21,4),    

 RESTRUCTURED_CCF DECIMAL(21,4),    

    

 RATED_Eligible DECIMAL(21,4),    

 RATED_Not_Eligible DECIMAL(21,4),    

 UNRATED DECIMAL(21,4),    

 RWA DECIMAL(21,4),    

    

 ISSUER_FACILITY varchar(10),    

 ISSUER_RATING varchar(10),    

 ISSUER_RATING_ELIGIBLE DECIMAL(21,4)    

)    

    

    

insert into #temp    

select     

sbu.sbu_description, CUST_LIMITS.customer_code, cmast.customer_name,    

ISNULL(consol_rating,'UNRATED') consol_rating,     

case when CONVERT(BIGINT,REPLACE(CUST_LIMITS.customer_code,'DWH',''))   <=0 then null else TRANS.INDUSTRY end INDUSTRY, 

  

NULL SOURCE_FLAG,    

    

isnull(margin_amount,0) margin_amount_UCC,     

    

CASE WHEN isnull(CUST_LIMITS.LIMIT,0) - sum(isnull(trans.gross_principal_outstanding_amount,0) + isnull(trans.contingent_liability,0)) < 0    

  THEN 0     

  ELSE isnull(CUST_LIMITS.LIMIT,0) - sum(isnull(trans.gross_principal_outstanding_amount,0) + isnull(trans.contingent_liability,0))     

END GROSS_OUTSTANDING,    

    

isnull(case when rank in (1,2) then 50 else 20 end,20) CCF,    

    

CASE WHEN isnull(CUST_LIMITS.LIMIT,0) - sum(isnull(trans.gross_principal_outstanding_amount,0) + isnull(trans.contingent_liability,0)) < 0    

  THEN 0     

  ELSE isnull(CUST_LIMITS.LIMIT,0) - sum(isnull(trans.gross_principal_outstanding_amount,0) + isnull(trans.contingent_liability,0))     

END * isnull(case when rank in (1,2) then 50 else 20 end,20)/100 GROSS_CCF,    

    

    

CASE WHEN isnull(CUST_LIMITS.LIMIT,0) - sum(isnull(trans.gross_principal_outstanding_amount,0) + isnull(trans.contingent_liability,0)) < 0    

  THEN 0     

  ELSE isnull(CUST_LIMITS.LIMIT,0) - sum(isnull(trans.gross_principal_outstanding_amount,0) + isnull(trans.contingent_liability,0))     

END * isnull(case when rank in (1,2) then 50 else 20 end,20)/100 - isnull(margin_amount,0) NET_OUTSTANDING,    

    

0 CRE_GROSS,    

0 CRE_CCF,    

0 CME_GROSS,    

0 CME_CCF,    

0 NBFC_GROSS,    

0 NBFC_CCF,    

0 NPA_GROSS,    

0 NPA_CCF,    

0 RESTRUCTURED_GROSS,    

0 RESTRUCTURED_CCF,    

    

0 RATED_Eligible,     

0 RATED_Not_Eligible,     

0 UNRATED,    

0 RWA,    

    

NULL ISSUER_FACILITY,    

NULL ISSUER_RATING,    

0 ISSUER_RATING_ELIGIBLE    

    

from PF_CUST_LIMITS CUST_LIMITS    

left join exp_trans trans    

 ON trans.CUSTOMER_CODE = CUST_LIMITS.CUSTOMER_CODE    

 and trans.mon_yr = @mstart_date    

 and trans.source_file = 'PERFORM'    

    

LEFT OUTER JOIN /*MARGIN*/    

 (    

 SELECT CUSTOMER_CODE, SUM(MARGIN_AMOUNT) margin_amount FROM EXP_MARGIN_DATA     

 WHERE DATA_PERIOD = @mstart_date    

 AND PRODUCT_CODE = 293    

 GROUP BY CUSTOMER_CODE    

 ) MAR    

 ON CUST_LIMITS.CUSTOMER_CODE = MAR.CUSTOMER_CODE    

    

left JOIN PF_CUST_MAST CMAST     

 ON CUST_LIMITS.CUSTOMER_CODE = CMAST.CUSTOMER_CODE    

    

left join pf_sbu_mast sbu    

on sbu.sbu_code = cmast.asset_sbu_code    

    

LEFT JOIN #internal_rating int_rat on int_rat.customer_code = CUST_LIMITS.CUSTOMER_CODE    

    

where CUST_LIMITS.mon_yr = @mstart_date    

group by CUST_LIMITS.customer_code, CMAST.Customer_name, MAR.margin_amount, CUST_LIMITS.LIMIT,     

   sbu.sbu_description, TRANS.INDUSTRY, consol_rating, rank    

    

    

    

/*CALCULATION FOR NPA*/    

update #temp     

set source_flag = 'NPA',     

 NPA_GROSS = GROSS_OUTSTANDING,    

 NPA_CCF = GROSS_CCF    

where CONVERT(BIGINT,REPLACE(ucc,'DWH','')) > 0    

and ucc in    

(    

 SELECT CUSTOMER_CODE FROM EXP_NPA NPA    

 INNER JOIN exp_trans tr    

  ON NPA.SOURCE_CUSTOMER_CODE = tr.SOURCE_CUSTOMER_CODE    

 WHERE npa.DATA_PERIOD = @mstart_date    

  AND npa.SYSTEM_CODE = 1     

  AND tr.ccif_system_code IN ('1')    

  and tr.mon_yr = @mstart_date    

  and tr.source_file = 'PERFORM'    

 GROUP BY tr.CUSTOMER_CODE    

)     

    

/*    

/*CALCULATION FOR RESTRUCTURED*/    

update #temp    

set SOURCE_FLAG = 'RESTRUCTURED', RESTRUCTURED = NET_OUTSTANDING     

FROM #temp TMP    

WHERE ISNULL(TMP.SOURCE_FLAG,'XXX') NOT IN ('NPA')    

and ucc > 0     

and tmp.ucc in    

( SELECT tr.CUSTOMER_CODE FROM exp_restructured_list list    

 INNER JOIN exp_trans tr    

  ON list.SOURCE_CUSTOMER_CODE = tr.SOURCE_CUSTOMER_CODE    

 WHERE list.as_on_date = @mstart_date    

  AND list.ccif_system_code = 1     

  AND tr.ccif_system_code IN ('1')    

  and tr.mon_yr = @mstart_date    

  and tr.source_file = 'PERFORM'    

 GROUP BY tr.CUSTOMER_CODE    

)    

*/    

    

/*CALCULATION FOR NBFC*/    

update #temp    

set SOURCE_FLAG = 'NBFC',     

 NBFC_GROSS = GROSS_OUTSTANDING,    

 NBFC_CCF = GROSS_CCF     

FROM #temp TMP    

 where ISNULL(INDUSTRY,0) IN (68)    

 and CONVERT(BIGINT,REPLACE(ucc,'DWH','')) > 0     

 AND ISNULL(TMP.SOURCE_FLAG,'XXX') NOT IN ('NPA')    

    

    

/*CALCULATION FOR CRE (UCC)*/    

update #temp    

set SOURCE_FLAG = 'CRE(UCC)',     

 CRE_GROSS = GROSS_OUTSTANDING,    

 CRE_CCF = GROSS_CCF     

FROM #temp TMP    

INNER JOIN PF_COMMERCIAL_REAL_ESTATE CRE    

ON TMP.UCC = CRE.ACCOUNT_NO    

where CONVERT(BIGINT,REPLACE(ucc,'DWH','')) > 0     

 AND CRE.SYSTEM_NAME = 'UCC'    

 AND CRE.TYPE = 'CUSTOMER_CODE'    

 AND CRE.MON_YR = @mstart_date    

 AND ISNULL(TMP.SOURCE_FLAG,'XXX') NOT IN ('NPA','NBFC')    

    

    

    

/*Rating update - start*/    

    

update #temp set     

 ISSUER_RATING = rating.rating_code,     

 ISSUER_FACILITY = rating.facility,    

 ISSUER_RATING_ELIGIBLE = ISNULL(GROSS_OUTSTANDING,0) - (ISNULL(NPA_gross,0) + ISNULL(RESTRUCTURED_gross,0) + ISNULL(NBFC_gross,0) + ISNULL(CME_gross,0) + ISNULL(CRE_gross,0))    

    

from #temp tmp    

inner join exp_capad_external_rating rating    

 on tmp.ucc = rating.customer_code    

where rating.mon_yr = @mstart_date    

and rating.facility = 'ALL'    

/*Rating update - end*/    

    

    

/*CALCULATE RESIDUAL*/    

    

/*Rated Eligible for ALL facility - start*/    

    

update #temp /*point 2: to update the remaining rows for ucc with ALL facility*/    

set      

 ISSUER_RATING = fac_all.ISSUER_RATING,     

 ISSUER_FACILITY = fac_all.ISSUER_FACILITY,    

 ISSUER_RATING_ELIGIBLE = TMP.RATED_Not_Eligible,    

 RATED_Not_Eligible = 0    

from #temp tmp    

inner join     

(select ucc, ISSUER_RATING, ISSUER_FACILITY from #temp where isnull(ISSUER_FACILITY,'XXXX') = 'ALL') fac_all    

on tmp.ucc = fac_all.ucc    

where isnull(tmp.ISSUER_FACILITY,'XXXX') <> 'ALL'    

    

    

update #temp /*point 1: to update the UCC not having ALL in universe but in EXTERNAL_RATING*/    

set      

 ISSUER_RATING = ext_rat.rating_code,     

 ISSUER_FACILITY = ext_rat.facility,    

 ISSUER_RATING_ELIGIBLE = TMP.RATED_Not_Eligible,    

 RATED_Not_Eligible = 0    

from #temp tmp    

inner join     

(select customer_code,facility,rating_code from exp_capad_external_rating     

 where mon_yr = @mstart_date and facility = 'ALL') ext_rat    

on tmp.ucc = ext_rat.customer_code    

left join     

(select distinct ucc from #temp where isnull(ISSUER_FACILITY,'XXXX') = 'ALL') fac_all    

on tmp.ucc = fac_all.ucc    

where fac_all.ucc is null    

    

/*Rated Eligible for ALL facility - end*/    

    

    

UPDATE #TEMP    

SET UNRATED = ISNULL(GROSS_OUTSTANDING,0) - (ISNULL(NPA_gross,0) + ISNULL(RESTRUCTURED_gross,0) + ISNULL(NBFC_gross,0) + ISNULL(CME_gross,0) + ISNULL(CRE_gross,0))    

WHERE UCC not in     

(select ucc from #temp where isnull(ISSUER_FACILITY,'XXXX') = 'ALL')    

    

    

/*inserting into exp_report_capad_data - start*/    

delete from exp_report_capad_data where mon_yr = @mstart_date and report_type = 'Finacle-Undrawn'    

    

insert into exp_report_capad_data     

(report_type, mon_yr,     

 customer_code, customer_name, sbu_description, consol_rating, facility, industry_name, source_flag,     

 margin_amount_ucc,    

 gross_outstanding, ccf, gross_ccf, net_outstanding,     

 cre_gross,cre_ccf, cme_gross,cme_ccf, nbfc_gross,nbfc_ccf, npa_gross,npa_ccf,    

 restructured_gross,restructured_ccf,    

 facility_rated_eligible, facility_rated_not_eligible, facility_unrated,     

 rwa, issuer_facility, issuer_rating, issuer_rating_eligible)    

select 'Finacle-Undrawn', @mstart_date,    

 ucc, cname, sbu, consol_rating, NULL facility,     

 (CASE WHEN industry = 1225 THEN 'BANK' ELSE 'NON BANK' END)industry,     

 source_flag,     

 margin_amount_ucc,    

 sum(gross_outstanding) gross_outstanding,     

 ccf, sum(gross_ccf) gross_ccf,    

 (case when sum(net_outstanding) < 0 then 0 else sum(net_outstanding) end) net_outstanding,     

 sum(cre_gross) cre_gross, sum(cre_ccf) cre_ccf,    

 sum(cme_gross) cme_gross, sum(cme_ccf) cme_ccf,    

 sum(nbfc_gross) nbfc_gross, sum(nbfc_ccf) nbfc_ccf,    

 sum(npa_gross) npa_gross, sum(npa_ccf) npa_ccf,    

 sum(restructured_gross) restructured_gross, sum(restructured_ccf) restructured_ccf,    

 sum(RATED_Eligible) facility_rated_eligible,    

 sum(RATED_Not_Eligible) facility_rated_not_eligible,    

 sum(UNRATED) facility_unrated,    

 SUM(RWA) RWA,    

 ISSUER_FACILITY,    

 ISSUER_RATING,    

 SUM(ISSUER_RATING_ELIGIBLE)ISSUER_RATING_ELIGIBLE    

from #temp temp    

group by ucc,cname,sbu,consol_rating,industry,source_flag,margin_amount_ucc,ccf,    

  ISSUER_FACILITY,ISSUER_RATING    

having sum(gross_outstanding) > 0    

/*inserting into exp_report_capad_data - end*/    

    

update statistics exp_report_capad_data with fullscan --SC03Mar2015

    

select report_type, mon_yr,     

 customer_code, customer_name, sbu_description, consol_rating, facility, industry_name, source_flag,     

 margin_amount_ucc,    

 gross_outstanding, ccf, gross_ccf, net_outstanding,     

 cre_gross,cre_ccf, cme_gross,cme_ccf, nbfc_gross,nbfc_ccf, npa_gross,npa_ccf,    

 restructured_gross,restructured_ccf,    

 facility_rated_eligible, facility_rated_not_eligible, facility_unrated,     

 rwa, issuer_facility, issuer_rating, issuer_rating_eligible    

from exp_report_capad_data     

where mon_yr = @mstart_date and report_type = 'Finacle-Undrawn'    

ORDER BY customer_code, facility, facility_rating    

    

end 

SET NOCOUNT OFF