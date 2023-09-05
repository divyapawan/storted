CREATE proc [perform].[pr_capad_ibg_undrawn] (@mstart_date datetime)    

as    

SET NOCOUNT ON    

/*    

Created By : Mustafa Pehlari    

Created On : 28-Dec-2009    

Reason  : CRPER21962: Computation of Capital Adequancy (CAPAD) reports    

*/    

    

BEGIN    

    

--declare @mstart_date datetime    

--set @mstart_date='31-mar-09'    

    

    

/*Undrawn uses Fund & Nonfund data. hence validation added to check the same*/    

if(select count(*) from exp_report_capad_data where mon_yr =  @mstart_date and report_type in('IBG-Fund')) = 0     

begin    

 select 'ERROR - Cannot execute IBG Undrawn since IBG Fund for ' + convert(varchar(12),@mstart_date,106) + ' is not yet executed. Process aborted'    

 return    

end    

    

if(select count(*) from exp_report_capad_data where mon_yr =  @mstart_date and report_type in('IBG-Non Fund')) = 0     

begin    

 select 'ERROR - Cannot execute IBG Undrawn since IBG Non-fund for ' + convert(varchar(12),@mstart_date,106) + ' is not yet executed. Process aborted'    

 return    

end    

    

    

DECLARE @NPA DECIMAL(21,2), @NBFC DECIMAL(21,2), @CRE DECIMAL(21,4), @CME DECIMAL(21,4), @REST DECIMAL(21,4)    

    

SELECT @CME = SUM(CASE WHEN CATEGORY = 'CAPITAL MARKET EXPOSURE' THEN RISK_WEIGHTAGE ELSE 0 END),    

@CRE = SUM(CASE WHEN CATEGORY = 'COMMERCIAL REAL ESTATE EXPOSURE' THEN RISK_WEIGHTAGE ELSE 0 END),    

@NBFC = SUM(CASE WHEN CATEGORY = 'NBFC EXPOSURE' THEN RISK_WEIGHTAGE ELSE 0 END),    

@NPA = SUM(CASE WHEN CATEGORY = 'NPA EXPOSURE' THEN RISK_WEIGHTAGE ELSE 0 END),    

@REST = SUM(CASE WHEN CATEGORY = 'RESTRUCTURED EXPOSURE' THEN RISK_WEIGHTAGE ELSE 0 END)    

FROM PF_CATEGORY_RISK_WEIGHTAGE    

WHERE @mstart_date BETWEEN FROM_DATE AND TO_DATE    

    

    

create table #temp    

(    

 sbu varchar(100),    

 ucc varchar(255),    

 cname varchar(100),    

 RATING varchar(10),    

 facility varchar(10),    

 INDUSTRY VARCHAR(25),    

 SOURCE_FLAG VARCHAR(25),    

    

 COUNTER_PARTY_TYPE VARCHAR(20),    

 RES_STATUS VARCHAR(20),    

    

 MARGIN_AMOUNT_UCC DECIMAL(21,4),    

 MARGIN_AMOUNT_PRO DECIMAL(21,4),    

 GROSS_OUTSTANDING DECIMAL(21,4),    

 CCF DECIMAL(21,4),    

 GROSS_CCF DECIMAL(21,4),    

 NET_OUTSTANDING DECIMAL(21,4),    

    

 CRE_Gross DECIMAL(21,4),    

 CRE_ccf DECIMAL(21,4),    

 CME_Gross DECIMAL(21,4),    

 CME_ccf DECIMAL(21,4),    

 NBFC_gross DECIMAL(21,4),    

 NBFC_ccf DECIMAL(21,4),    

 NPA_gross DECIMAL(21,4),    

 NPA_ccf DECIMAL(21,4),    

 RESTRUCTURED_gross DECIMAL(21,4),    

 RESTRUCTURED_ccf DECIMAL(21,4),    

    

 RATED_Eligible DECIMAL(21,4),    

 RATED_Not_Eligible DECIMAL(21,4),    

 UNRATED DECIMAL(21,4),    

 RWA DECIMAL(21,4),    

    

 ISSUER_FACILITY varchar(10),    

 ISSUER_RATING varchar(10),    

 ISSUER_RATING_ELIGIBLE DECIMAL(21,4)    

)    

    

    

insert into #temp    

select sbu_description, TAB.UCC, TAB.CNAME, TAB.RATING RATING, TAB.FACILITY FACILITY, TAB.INDUSTRY INDUSTRY,    

CAST (NULL AS VARCHAR(25)) SOURCE_FLAG,    

    

counter_party_type,    

res_status,    

    

TAB.MARGIN_AMOUNT MARGIN_AMOUNT_UCC,    

0 MARGIN_AMOUNT_PRO,    

TAB.GROSS_OUTSTANDING GROSS_OUTSTANDING,     

CCF,    

GROSS_CCF,    

TAB.GROSS_OUTSTANDING NET_OUTSTANDING,     

    

0 CRE_gross,    

0 CRE_ccf,    

0 CME_gross,    

0 CME_ccf,    

0 NBFC_gross,    

0 NBFC_ccf,    

0 NPA_gross,    

0 NPA_ccf,    

0 RESTRUCTURED_gross,    

0 RESTRUCTURED_ccf,    

    

0 RATED_Eligible,     

0 RATED_Not_Eligible,     

0 UNRATED,    

0 RWA,    

    

NULL ISSUER_FACILITY,    

NULL ISSUER_RATING,    

0 ISSUER_RATING_ELIGIBLE    

    

from    

(/*IBG Fund*/    

select sbu.sbu_description, trans.customer_code UCC, CMAST.CUSTOMER_NAME CNAME,     

  RATING.RATING_CODE RATING, FAC.FACILITY_MAPPING FACILITY,     

  CASE WHEN CONVERT(BIGINT,REPLACE(trans.customer_code,'DWH',''))  <= 0 THEN null ELSE     

   (CASE WHEN TRANS.INDUSTRY = 1225 THEN 'BANK' ELSE 'NON BANK' END) end INDUSTRY,    

sum(isnull(trans.sanctioned_amount,0) - isnull(trans.gross_principal_outstanding_amount,0)) GROSS_OUTSTANDING,    

  isnull(MAR.margin_amount,0) MARGIN_AMOUNT,    

    

  0 CCF,    

  sum(isnull(trans.sanctioned_amount,0) - isnull(trans.gross_principal_outstanding_amount,0)) GROSS_CCF,    

  counter_party_type,    

  res_status    

    

from exp_trans trans    

inner join exp_obu obu    

 on trans.customer_code = obu.customer_code    

 and trans.source_product_code = obu.source_product_code    

END

SET NOCOUNT OFF

