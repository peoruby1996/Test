SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER proc [dbo].[sp_PUR0045_SaveData]      
(      
@Mode as int,      
@strError varchar(800) output,      
@pXMLDoc1 as xml,      
@Computer varchar(100),      
@Operator varchar(10)      
)      
as      
       
BEGIN      
BEGIN TRY      
 BEGIN TRANSACTION      
       
 declare @iXML as INT,@Exit_Code int,@M_SAKUSEI varchar(2)      
       
 declare @Juchuno numeric(18,0)      
 declare @Yen numeric(9,2),@Vnd numeric(9,2)      
 declare @PType varchar(20)      
 declare @hinb varchar(25)      
       
 declare @PA int      
      
exec sp_xml_preparedocument @iXML OUTPUT,@pXMLDoc1      
         
           
set @M_SAKUSEI=(select Tanto_ryaku from OPERATMF where Operator_code=@Operator) --Get Operater      
set @Juchuno = (select SEQ_NO1 from SEQNOMF where RENBAN_KUBUN = 9)      
update SEQNOMF set SEQ_NO1 = SEQ_NO1 + 1 where RENBAN_KUBUN = 9      
set @hinb = (select [ITEM_CODE] from OPENXML(@iXML,'/DocumentElement/XmlUpdate',2) WITH( ITEM_CODE varchar(25) ))      
set @Yen = (select [YEN_USD] from OPENXML(@iXML,'/DocumentElement/XmlUpdate',2) WITH( YEN_USD numeric(9,2) ))      
set @Vnd = (select [VND_USD] from OPENXML(@iXML,'/DocumentElement/XmlUpdate',2) WITH( VND_USD numeric(9,2) ))      
set @PType = (select [ITEM_TYPE] from OPENXML(@iXML,'/DocumentElement/XmlUpdate',2) WITH( ITEM_TYPE varchar(20) ))      
--set @juchu_renban = (select [JUCHU_RENBAN] from ORDERRF where JUCHUNO = (select JUCHUNO from OPENXML(@iXML,'/DocumentElement/ORDERRF',2) WITH( JUCHUNO int )) and MUKOU_KUBUN <> '*')      
      
----------------------= Update ExchangeRate =-----------------------------      
--Update EXCHANGERATERF set EXCHANGE_RATE = @Yen where RATE_CODE = 'YEN-USD'      
--Update EXCHANGERATERF set EXCHANGE_RATE = @Vnd where RATE_CODE = 'VND-USD'      
--------------------------------------------------------------------------      
      
---------------------------------------------------= Update Plastc && Insert Paramerf =-----------------------------------------------------------------      
  
if @PType = 'Material' 
 begin      
  if (select top 1 1 from PARAMERF where item_code=@hinb)=1    
  BEGIN

  ----------------------------------------------------------= Plastc =----------------------------------------------------------------------------      
  Update P      
        
  set P.PLA_YOBI6 = xm.[LEAD_TIME],P.ANZEN_ZAIKO_SU = xm.[SAFETY_STOCK],P.PLA_YOBI1 = xm.[ROUND_QUANTITY],P.UNIT = xm.[UNIT],P.MOQ = xm.[MOQ]      
   --,P.UNIT_PRICE = xm.[UNIT_PRICE],
  --, P.CURRENCY = xm.[CURRENCY],

 , P.TRADE_TERM = xm.[TRADE_TERM],P.FORECAST_REQ = xm.[FORECAST_REQ]      
   ,P.TRANSPORTATION = xm.[TRANSPORTATION],P.CUSTOMER_CLEARANCE = xm.[CUSTOMER_CLEARANCE]      
   ,P.DATA_KUBUN = xm.[MSC],P.CUSTOMER_FLAG = xm.[CUSTOMER_FLAG],P.PERCENT_NG_RATE = xm.[PERCENT_NG_RATE],P.EXP_CONTROL = xm.[EXP_CONTROL]      
   ,P.EXP_DATE = xm.[EXP_DATE],P.FIFO_LOT = xm.[FIFO_LOT],P.FIFO_INPUT_DATE = xm.[FIFO_INPUT_DATE]      
  , P.Safety_LT = XM.[Safety_LT],P.Prod_LT = XM.[Prod_LT]
  ,P.HACHU_PLAN_JOUGEN = xm.[UPPER_ORDER_PLAN],P.PLA_YOBI2 = XM.[EXTEND_POCP]
   ,p.QuoNo = xm.QuoNo,p.QuoDate = xm.QuoDate,p.EffectiveDate = xm.EffDate,p.Comment = xm.Comment
   ,p.Shortage_Rate = xm.ShRate

  from  PLASTCMF P      
  inner join OPENXML(@iXML,'/DocumentElement/XmlUpdate',2) WITH( ITEM_CODE varchar(25),LEAD_TIME smallint,SAFETY_STOCK numeric(18,2),MSC char(1),      
     ROUND_QUANTITY numeric(18,2),UNIT varchar(40),MOQ numeric(18,2),UNIT_PRICE numeric(18,4),CURRENCY varchar(5),TRADE_TERM varchar(30),      
     FORECAST_REQ int,TRANSPORTATION varchar(30),CUSTOMER_CLEARANCE int,FIFO_LOT char(1),CUSTOMER_FLAG char(1),      
     PERCENT_NG_RATE char(1),EXP_CONTROL char(1),EXP_DATE numeric(9,2),FIFO_INPUT_DATE char(1), Safety_LT int, Prod_LT int, EXTEND_POCP int,UPPER_ORDER_PLAN int
	  ,QuoNo varchar(100),QuoDate datetime,EffDate datetime,Comment nvarchar(500),ShRate float)xm on P.ZAIRYO_HINBAN = xm.ITEM_CODE           
  ------------------------------------------------------------------------------------------------------------------------------------------------      
           Update PR    
   SET ITEM_TYPE=@PType,SUPPLIER_CODE=xm.SUPPLIER_CODE,LEAD_TIME=xm.LEAD_TIME,SAFETY_STOCK=xm.SAFETY_STOCK,ROUND_QUANTITY=xm.ROUND_QUANTITY,UNIT=xm.UNIT,MOQ=xm.MOQ,    
         TRADE_TERM=xm.TRADE_TERM,FORECAST_REQ=xm.FORECAST_REQ,TRANSPORTATION=xm.TRANSPORTATION,CUSTOMER_CLEARANCE=xm.CUSTOMER_CLEARANCE,
		 UPPER_ORDER_PLAN=xm.UPPER_ORDER_PLAN ,
		 MSC=xm.MSC      
       --,CHEMICAL_FLAG=xm.CHEMICAL_FLAG,
	   ,CUSTOMER_FLAG=xm.CUSTOMER_FLAG,PERCENT_NG_RATE=xm.PERCENT_NG_RATE,EXP_CONTROL=xm.EXP_CONTROL,EXP_DATE=xm.EXP_DATE,FIFO_LOT=xm.FIFO_LOT,FIFO_INPUT_DATE=xm.FIFO_INPUT_DATE   
    ,INPUT_PERSON=@M_SAKUSEI,INPUT_DATE   =GETDATE() 
	 ,Pr.Safety_LT = XM.[Safety_LT],Pr.Prod_LT = XM.[Prod_LT]
       --,Safety_LT=xm.Safety_LT,Prod_LT=xm.Prod_LT,
	  , EXTEND_POCP =xm.EXTEND_POCP  
      ,pr.QuoNo = xm.QuoNo,pr.QuoDate = xm.QuoDate,pr.EffectiveDate = xm.EffDate,pr.Comment = xm.Comment
	  ,pr.Shortage_Rate = xm.ShRate
  ----set P.HA_READ_TIME = xm.[LEAD_TIME],P.ANZEN_ZAIKO = xm.[SAFETY_STOCK],P.MARUME_SURYO = xm.[ROUND_QUANTITY],P.UNIT = xm.[UNIT],P.MOQ = xm.[MOQ]      
  ---- --,P.UNIT_PRICE = xm.[UNIT_PRICE],P.CURRENCY = xm.[CURRENCY]    
  ---- ,P.TRADE_TERM = xm.[TRADE_TERM],P.FORECAST_REQ = xm.[FORECAST_REQ]      
  ---- ,P.TRANSPORTATION = xm.[TRANSPORTATION],P.CAN_DRUM = xm.[CAN_DRUM],P.CUSTOMER_CLEARANCE = xm.[CUSTOMER_CLEARANCE]      
  ---- ,P.HACHU_PLAN_JOUGEN = xm.[UPPER_ORDER_PLAN],P.PA_FLAG1 = xm.[MSC],P.C_FLAG = xm.[CHEMICAL_FLAG]      
  ---- ,P.CUSTOMER_FLAG = xm.[CUSTOMER_FLAG],P.PERCENT_NG_RATE = xm.[PERCENT_NG_RATE],P.EXP_CONTROL = xm.[EXP_CONTROL],P.MASTER_UP_OP = @M_SAKUSEI      
  ---- ,P.EXP_DATE = xm.[EXP_DATE],P.FIFO_LOT = xm.[FIFO_LOT],P.FIFO_INPUT_DATE = xm.[FIFO_INPUT_DATE],P.MASTER_UP_DATE = GETDATE()      
  ---- ,,P.PLA_YOBI2 = XM.[EXTEND_POCP], P.Packing_Flag = XM.[Packing_Flag]      
           
  from  PARAMERF PR      
  inner join OPENXML(@iXML,'/DocumentElement/XmlUpdate',2) WITH( ITEM_CODE varchar(25),SUPPLIER_CODE int,LEAD_TIME smallint,SAFETY_STOCK numeric(18,2),      
     ROUND_QUANTITY numeric(18,2),UNIT varchar(40),MOQ numeric(18,2),UNIT_PRICE numeric(18,4),CURRENCY varchar(5),TRADE_TERM varchar(30),      
     FORECAST_REQ int,TRANSPORTATION varchar(30),CUSTOMER_CLEARANCE int,MSC char(1),CUSTOMER_FLAG char(1),PERCENT_NG_RATE char(1),      
     EXP_CONTROL char(1),EXP_DATE numeric(9,2),FIFO_LOT char(1),FIFO_INPUT_DATE char(1),UNIT_PRICE_USD numeric(18,4), Safety_LT int, Prod_LT int, EXTEND_POCP int,UPPER_ORDER_PLAN int
	 ,QuoNo varchar(100),QuoDate datetime,EffDate datetime,Comment nvarchar(500),ShRate float)xm  ON XM.ITEM_CODE=PR.ITEM_CODE 
end  
ELSE

  ----------------------------------------------------------= Paramerf =--------------------------------------------------------------------------      
  INSERT INTO PARAMERF(DATA_NO,YEN_USD,VND_USD,ITEM_TYPE,ITEM_CODE,SUPPLIER_CODE,LEAD_TIME,SAFETY_STOCK,ROUND_QUANTITY,UNIT,MOQ      
       ,TRADE_TERM,FORECAST_REQ,TRANSPORTATION,CUSTOMER_CLEARANCE,MSC,CUSTOMER_FLAG,PERCENT_NG_RATE      
       ,EXP_CONTROL,EXP_DATE,FIFO_LOT,FIFO_INPUT_DATE,INPUT_PERSON,INPUT_DATE,Safety_LT,Prod_LT,EXTEND_POCP,UPPER_ORDER_PLAN,QuoNo,QuoDate,EffectiveDate,Comment,Shortage_Rate)      
             
  select @Juchuno,@Yen,@Vnd,@PType,xm.ITEM_CODE,xm.SUPPLIER_CODE,xm.LEAD_TIME,xm.SAFETY_STOCK,xm.ROUND_QUANTITY,xm.UNIT,xm.MOQ      
    ,xm.TRADE_TERM,xm.FORECAST_REQ,xm.TRANSPORTATION,xm.CUSTOMER_CLEARANCE,xm.MSC,xm.CUSTOMER_FLAG      
    ,xm.PERCENT_NG_RATE,xm.EXP_CONTROL,xm.EXP_DATE,xm.FIFO_LOT,xm.FIFO_INPUT_DATE,@M_SAKUSEI,GETDATE()  ,XM.[Safety_LT]   ,XM.[Prod_LT],xm.EXTEND_POCP ,xm.UPPER_ORDER_PLAN    
	,xm.QuoNo,xm.QuoDate,xm.EffDate,xm.Comment,xm.ShRate
        
  from OPENXML(@iXML,'/DocumentElement/XmlUpdate',2) WITH( ITEM_CODE varchar(25),SUPPLIER_CODE int,LEAD_TIME smallint,SAFETY_STOCK numeric(18,2),      
     ROUND_QUANTITY numeric(18,2),UNIT varchar(40),MOQ numeric(18,2),UNIT_PRICE numeric(18,4),CURRENCY varchar(5),TRADE_TERM varchar(30),      
     FORECAST_REQ int,TRANSPORTATION varchar(30),CUSTOMER_CLEARANCE int,MSC char(1),CUSTOMER_FLAG char(1),PERCENT_NG_RATE char(1),      
     EXP_CONTROL char(1),EXP_DATE numeric(9,2),FIFO_LOT char(1),FIFO_INPUT_DATE char(1),UNIT_PRICE_USD numeric(18,4), Safety_LT int, Prod_LT int,EXTEND_POCP int,UPPER_ORDER_PLAN int
	 ,QuoNo varchar(100),QuoDate datetime,EffDate datetime,Comment nvarchar(500),ShRate float)xm           
  ------------------------------------------------------------------------------------------------------------------------------------------------         
 
   Update P      
        
  set P.PLA_YOBI6 = xm.[LEAD_TIME],P.ANZEN_ZAIKO_SU = xm.[SAFETY_STOCK],P.PLA_YOBI1 = xm.[ROUND_QUANTITY],P.UNIT = xm.[UNIT],P.MOQ = xm.[MOQ]      
   --,P.UNIT_PRICE = xm.[UNIT_PRICE],
  --, P.CURRENCY = xm.[CURRENCY],

 , P.TRADE_TERM = xm.[TRADE_TERM],P.FORECAST_REQ = xm.[FORECAST_REQ]      
   ,P.TRANSPORTATION = xm.[TRANSPORTATION],P.CUSTOMER_CLEARANCE = xm.[CUSTOMER_CLEARANCE]      
   ,P.DATA_KUBUN = xm.[MSC],P.CUSTOMER_FLAG = xm.[CUSTOMER_FLAG],P.PERCENT_NG_RATE = xm.[PERCENT_NG_RATE],P.EXP_CONTROL = xm.[EXP_CONTROL]      
   ,P.EXP_DATE = xm.[EXP_DATE],P.FIFO_LOT = xm.[FIFO_LOT],P.FIFO_INPUT_DATE = xm.[FIFO_INPUT_DATE]  ,P.Safety_LT = XM.[Safety_LT],P.Prod_LT = XM.[Prod_LT]    
   , P.HACHU_PLAN_JOUGEN = xm.[UPPER_ORDER_PLAN],P.PLA_YOBI2 = XM.[EXTEND_POCP]
   ,p.QuoNo = xm.QuoNo,p.QuoDate = xm.QuoDate,p.EffectiveDate = xm.EffDate,p.Comment = xm.Comment
   ,p.Shortage_Rate = xm.ShRate
  from  PLASTCMF P      
  inner join OPENXML(@iXML,'/DocumentElement/XmlUpdate',2) WITH( ITEM_CODE varchar(25),LEAD_TIME smallint,SAFETY_STOCK numeric(18,2),MSC char(1),      
     ROUND_QUANTITY numeric(18,2),UNIT varchar(40),MOQ numeric(18,2),UNIT_PRICE numeric(18,4),CURRENCY varchar(5),TRADE_TERM varchar(30),      
     FORECAST_REQ int,TRANSPORTATION varchar(30),CUSTOMER_CLEARANCE int,FIFO_LOT char(1),CUSTOMER_FLAG char(1),      
     PERCENT_NG_RATE char(1),EXP_CONTROL char(1),EXP_DATE numeric(9,2),FIFO_INPUT_DATE char(1),Safety_LT int, Prod_LT int,EXTEND_POCP int,UPPER_ORDER_PLAN int
	 ,QuoNo varchar(100),QuoDate datetime,EffDate datetime,Comment nvarchar(500),ShRate float)xm on P.ZAIRYO_HINBAN = xm.ITEM_CODE           

 end      
---------------------------------------------------------------------------------------------------------------------------------------------------------      
       
 set @strError = 'OK'      
      
 /* ======== Insert LogFile ======== */      
 INSERT INTO LOGFILEWK ( HostName, LOGVALUE)      
 select @Computer, convert(varchar(10),getdate(),3) + '  ' + convert(varchar(10),getdate(),108) + ',PUR0040,' + @Operator + ',' +      
 xm.ITEM_CODE + ',' + isnull(convert(varchar(20),xm.LEAD_TIME),'') + ',' + isnull(CONVERT(varchar(20),xm.SAFETY_STOCK), '') + ',' +       
 isnull(convert(varchar(22),xm.ROUND_QUANTITY),'0') + ',' + ISNULL(convert(varchar(20),xm.UPPER_ORDER_PLAN),'') + ',' +       
 isnull(convert(varchar(20),xm.EXTEND_POCP),'') + ',' + isnull(xm.MSC,'') + ',' + isnull(xm.Packing_Flag,'')  + ',' +        
 isnull(xm.QuoNo,'') + ',' + (case when QuoDate is null then '19000101' else convert(varchar(10),QuoDate,3) end) + ',' + 
 (case when EffDate is null then '19000101' else convert(varchar(10),EffDate,3) end) + ',' + isnull(xm.Comment,'') + ',' + isnull(CONVERT(varchar(20),xm.ShRate), '')
 from OPENXML(@iXML,'/DocumentElement/XmlUpdate',2) WITH( ITEM_CODE varchar(25),LEAD_TIME smallint,SAFETY_STOCK numeric(18,2),      
     ROUND_QUANTITY numeric(18,2),UNIT varchar(40),MOQ numeric(18,2),UNIT_PRICE numeric(18,4),CURRENCY varchar(5),TRADE_TERM varchar(30),      
     FORECAST_REQ int,TRANSPORTATION varchar(30),CAN_DRUM varchar(20),CUSTOMER_CLEARANCE int,UPPER_ORDER_PLAN int,MSC char(1),      
     CHEMICAL_FLAG char(1),CUSTOMER_FLAG char(1),PERCENT_NG_RATE char(1),EXP_CONTROL char(1),EXP_DATE numeric(9,2),      
     FIFO_LOT char(1),FIFO_INPUT_DATE char(1),SUPPLIER_CODE int,UNIT_PRICE_USD numeric(18,4),      
     Safety_LT int, Prod_LT int, EXTEND_POCP int, Packing_Flag char(1),QuoNo varchar(100),QuoDate datetime,EffDate datetime
	 ,Comment nvarchar(500),ShRate float)xm      
      
exec sp_xml_removedocument @iXML      
      
      
      
 COMMIT TRAN      
END TRY      
       
 BEGIN CATCH      
  IF @@TRANCOUNT>0      
   ROLLBACK TRAN      
  set @strError=cast(ERROR_SEVERITY() as varchar) +' '+ERROR_MESSAGE()      
  print cast(ERROR_SEVERITY() as varchar) +' '+ERROR_MESSAGE()      
  print @strError      
 END CATCH      
       
      
END 
GO
