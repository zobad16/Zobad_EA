//+------------------------------------------------------------------+
//|                                             Swing_Ai_Gridv10.mq4 |
//|                                   Copyright 2017, Zobad Mahmood. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Zobad Mahmood."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#include "EntrySignal.mqh"
#include "MoneyManagement.mqh"
#include "Indicators.mqh"
//-------------------------------------------------------------------

EntrySignal     *algo ;
MoneyManagement *mm   ;
Indicators      *ind  ;

enum LotType
{
   MANUAL = 0,
   AUTO    = 1,
};
enum Take_Profit_Type{
   
   FIXED=0,
   VOLATILITY=1,
   MID_BB=2
};
enum _type
{
   FIX    = 0,      //Fixed
   VOLAT  = 1       //Volatility
};
enum Type
  {
   INCREASE = 1,// Increase
   DECREASE = 0,// Decrease
   SAME = 2,// Same
  };
int                    buy_counter=0;
int                    sell_counter=0;
input int              Magic_Number       = 1         ;             //Magic Number 
input bool             useLegacy          = false     ;             //Use Legacy Entry Signal
extern string          set="----------Consecutive Losses--------------";//Consecutive Losses Settings
input bool             useConsecutive     = false     ;             //Use Consecutive Loss
input int              noConsqLossAllowed = 3         ;             //Consecutive Losses Allowed
input double           percentReduction   = 5         ;             //Lot Size Percent Reduction
extern string          setLot=     "-------Lot Setting -------"       ;
input LotType          lotType            = AUTO      ;             //Lot Type
input double           _risk              = 2.0       ;             //%Available Balance::Lot
input double           LotSize            = 0.5       ;             //Position:: Lot Size(Manual)
extern string          order1=     "-------Order -------"             ;             //Order 1 Settings
bool                   order1Open         =  false    ; 
extern Strat_type      _strat_type        = DIRECTIONAL ;           //Strategy:: Type      
input bool             useStrategy1       = true      ;             //Strategy:: Use Strategy
input bool             useHedge           = false     ;             //Strategy:: Use Hegde 
extern string          reversalSet="-------Reversal Strategy -------" ;             //Reversal TP and SL Settings

input Take_Profit_Type TP_Type            = VOLATILITY;             //Reversal TP:: Type
input Take_Profit_Type SL_Type            = VOLATILITY;             //Reversal SL:: Type
input double           TP_Value           =  4.5      ;             //Reversal TP:: Volatility/Fixed(Points)
input double           SL_Value           =  1.5      ;             //Reversal SL:: Volatility/Fixed(Points)
input bool             useTrail           = false     ;             //Trail:: Use Trail
input _type            _trail_type1       = FIX       ;             //Trail:: Type 
input double           _trailBy           = 40        ;             //Trail Volat/Fixed:: Trail by
input bool             _breakEven1        = false     ;             //Breakeven:: Use jump to Breakeven
input int              _whenJump1         = 25        ;             //Breakeven:: When to Jump
input int              _jumpBy1           = 6         ;             //Breakeven:: Points to add after Jump

extern string          directionSet="-------Directional Strategy -------";             //Directional TP/SL Settings
input Take_Profit_Type TP_Type1           = VOLATILITY;             //Directional TP:: Type
input Take_Profit_Type SL_Type1           = VOLATILITY;             //Directional SL:: Type
input double           TP_Value1          =  3.5      ;             //Directional TP:: Volatility/Fixed(Points)
input double           SL_Value1          =  1.5      ;             //Directional SL:: Volatility/Fixed(Points)
input bool             useTrail2          = false     ;             //Trail:: Use Trail
input _type            _trail_type2       = FIX       ;             //Trail:: Type 
input double           _trailBy2          = 40        ;             //Trail Volat/Fixed:: Trail by
input bool             _breakEven2        = false     ;             //Breakeven:: Use jump to breakeven
input int              _whenJump2         = 25        ;             //Breakeven:: When to Jump
input int              _jumpBy2           = 6         ;             //Breakeven:: Points to add after Jump

extern string          gridSet="-------Grid Strategy -------";             //Directional TP/SL Settings
input bool             useGridding        = true      ;             //Grid::Use Grid
input bool             useGHedge          = false     ;             //Grid::Use Grid Hedge
input bool             _use1StopCloseAll  = true     ;             //Use 1 Stop Close All
input double           startLot           = 0.1       ;             //Grid::Starting lots
input int              numberOfLegs       = 0         ;             //Grid::Number of Legs
input  Type            legIncreaseDecrease= INCREASE  ;             //Grid::Leg Increase or decrease 
input int              increaseLLotBy     = 2         ;             //Grid::Leg Lot Increase Factor(in multiples)
input int              decreaseLLotBy     = 2         ;             //Grid::Leg Lot Decrease Factor(in multiples)
input double           pointsE            = 30        ;             //Grid::Points for next Entry
input Take_Profit_Type TP_Type3           = VOLATILITY;             //Grid TP:: Type
input Take_Profit_Type SL_Type3           = VOLATILITY;             //Grid SL:: Type
input double           TP_Value3          =  3.5      ;             //Grid TP:: Volatility/Fixed(Points)
input double           SL_Value3          =  1.5      ;             //Grid SL:: Volatility/Fixed(Points)
input bool             useTrail3          = false     ;             //Trail:: Use Trail
input _type            _trail_type3       = FIX       ;             //Trail:: Type 
input double           _trailBy3          = 40        ;             //Trail Volat/Fixed:: Trail by

input bool             EQ_Based           = true      ;             //Use Equity Based TP
input bool             useGridStop        = false     ;             //Us Equity Based SL
input double           _profitTarget      = 1000      ;             //Profit Target
input double           _stopLevel         = -500.0    ;             //Stop Out Level
input int              _timegap1          = 31        ;             //Order 1 time gap(in mins)
input bool             _use_risk_candle1  = false     ;             //Risk Management:: Use Risk Management
input int              _risk_candle1      = 4         ;             //Risk Management:: Number of Candles to read
double                 _highestStop1                  ;
double                 _lowestStop1                   ;
input bool             _gapCloseCheck1    = false     ;             //Close Candle:: Use time gap
input int              _whenClose1        = 50        ;             //Close Candel:: Time gap in minutes
bool                   LR_Flag            = false     ;      
double                 prev_lot           =0.0        ;
int                    _cur_total         = 0         ;
bool                   startFlag          = false     ;


//+------------------------------------------------------------------

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   startFlag = true ;
   algo = new EntrySignal()    ;
   mm   = new MoneyManagement();
   ind   = new Indicators()    ;   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   delete(algo);
   delete(mm)  ;
   delete(ind) ; 
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
  if(startFlag == true){
      Print("Start is false now");
      _cur_total = isOrdersTotal(Magic_Number);
      Print("Closed. _Cur_total[",_cur_total,"], isTotal[",isOrdersTotal(Magic_Number),"]");
      startFlag = false;
   }   Comment("EA Started. MG.NO[",Magic_Number,"]");
   if(LR_Flag ==false)
   {
      if(CheckLR()==true)LR_Flag =true;
   }
   if(useLegacy == true)
   {  
      if(algo.OrderOperationCode(Magic_Number)!=FAIL && useTrail==true)
      {
         mm.TrailOrder(_trail_type1,_trailBy,Magic_Number);
      }   
      if(IsNewBar())
      {
         int ccode = FAIL;
         int tcode = FAIL;
         tcode = algo.isSignalCandle(_strat_type,ccode);
         if((tcode == DIRECTIONAL_BUY||tcode==REVERSAL_BUY)&&(algo.OrderOperationCode(Magic_Number)==FAIL))
         {           
           Print("Buy Alert");
           bool res = Revised_Buy(ccode,tcode);
         }
         else if((tcode == DIRECTIONAL_SELL||tcode==REVERSAL_SELL)&&(algo.OrderOperationCode(Magic_Number)==FAIL))
         {     
           Print("Sell Alert");
           bool res = Revised_Sell(ccode,tcode);
         }         
      }
   }
   //------------------------------------------------------------
   else if(useLegacy == false)
   {      
      int comment =algo.OrderOperationCode(Magic_Number);
      if(isOrdersTotal(Magic_Number)>=1)
      {
         string com= StringSubstr((string)comment,1);
         string rb = ""+(string)REVERSAL_BUY     ;
         string db = ""+(string)DIRECTIONAL_BUY  ;
         string ds = ""+(string)DIRECTIONAL_SELL ;
         string rs = ""+(string)REVERSAL_SELL    ;
         if(useTrail2 ==true && (StringCompare(com,db)==0 || StringCompare(com,ds) ==0)){
            mm.TrailOrder(_trail_type2,_trailBy2,Magic_Number);
         }
         else if(useTrail == true && (StringCompare(com,rb)==0 || StringCompare(com,rs)==0)){
            mm.TrailOrder(_trail_type1,_trailBy,Magic_Number);
         }
        //-------------------------------------------------------------------------------
        //Grid Leg Entry
        bool useLast = true;
         if(useGridding==true)
         {
            if(useTrail3 == true){
               mm.TrailOrder(_trail_type3,_trailBy3,Magic_Number);
            }
            if(_use1StopCloseAll == true ){
              // Print("StopAll Current[",_cur_total,"], Total[",isOrdersTotal(Magic_Number),"]");
               if((isOrdersTotal(Magic_Number)<_cur_total)){
                  Print("StopAll Current[",_cur_total,"], Total[",isOrdersTotal(Magic_Number),"]");
                  mm.CloseAllOrders(Magic_Number);
                  _cur_total = isOrdersTotal(Magic_Number);
                  Print("Closed. _Cur_total[",_cur_total,"], isTotal[",isOrdersTotal(Magic_Number),"]");
               
               }
            }
            mm.EquityBasedClose(EQ_Based,_profitTarget,useGridStop,_stopLevel,Magic_Number);
            if(algo.OrderOperationCode(Magic_Number, BUY_LEG1) == true)
            {
               int bcount= 0   ;
               int op_code    = FAIL;
               int ccode      = FAIL;
               double alot    = 0.0 ;
               string c =(string)BUY_LEG1;
               //Print("c[",c,"]");
               algo.isExist(Magic_Number,c,bcount,op_code,alot);
              // Print("bCount[",bcount,"]Main");
               if( (algo.Pattern_Point_Negative(pointsE, Magic_Number) == REVERSAL_BUY)&& bcount<numberOfLegs)
               {
                  double nlot =0.0;
                 // if(useLast == true && isOrdersTotal(Magic_Number)<_cur_total){
                     nlot = CalculateLot2(numberOfLegs,increaseLLotBy);
                     Print("Lot Finding, Lot Size[",nlot,"]");
                 /* }
                  else{
                     prev_lot = mm.CalculatePositionSize(Magic_Number, BUY_LEG1);
                     nlot= prev_lot*increaseLLotBy;
                     prev_lot = nlot;
                     
                  }*/
                  ccode    = BUY_LEG1;
                  op_code  = DIRECTIONAL_BUY;
                  bool res = Revised_Buy(ccode,op_code,nlot);  
                  if(res == true ){
                     _cur_total += 1;   
                     Print("Leg EntryB: _cur_total[",_cur_total,"], isTotal[",isOrdersTotal(Magic_Number),"]");              
                  }
                  else{Print("Buy Order(Leg) Failed");}
               }
               
               else if(useGHedge==true && (algo.Pattern_Point_Negative(pointsE, Magic_Number) == REVERSAL_BUY)&& bcount==numberOfLegs)
               {
                  double pre_lot, n_lot =0.0;
                  int count , op_c;
                  bool leg1 = algo.isExist(Magic_Number,(string)BUY_LEG1,count,op_c,pre_lot);
                  bool leg2 = algo.isExist(Magic_Number,(string)BUY_LEG2,count,op_c,pre_lot);
                  if(leg1 == true && leg2 == false){
                     n_lot = mm.CalculatePositionSizeHedge(Magic_Number,BUY_LEG1);
                     //Print("_nLots[",n_lot,"]");
                  }
                  else if(leg1 == true && leg2 == true){
                     n_lot = mm.CalculatePositionSizeHedge(Magic_Number,BUY_LEG2);//Accumalative lot= prev_lot*increaseLLotBy;
                     //Print("_nLots[",n_lot,"]");
                  }
                  //----------------------------------------------------------
                  //Print("_nLots[",n_lot,"]");
                  prev_lot = n_lot;
                  ccode    = HEDGE_SELL;
                  op_code  = DIRECTIONAL_SELL;
                  bool res = Revised_Sell(ccode,op_code,n_lot);
                  if(res == true ) {
                     _cur_total += 1;
                  }
                
               }
            }
			else if(algo.OrderOperationCode(Magic_Number) == HEDGE_SELL)
            {}
            else if(algo.OrderOperationCode(Magic_Number) == SELL_LEG1)
               {
                 // prev_lot = mm.CalculatePositionSize(Magic_Number, SELL_LEG1);
                  int scount     = 0   ;
                  int op_code    = FAIL;
                  int ccode      = FAIL;
                  double alot    = 0.0 ;
                  string s = (string)SELL_LEG1;
                  algo.isExist(Magic_Number,""+(string)SELL_LEG1,scount,op_code,alot);
                  //Print("s[",s,"]");
                  //Print("SCount[",scount,"]Main");
                  if( (algo.Pattern_Point_Negative(pointsE,Magic_Number) == REVERSAL_SELL)&& scount<numberOfLegs)
                  {
                     double nlot =0.0;
                   // if(useLast == true && isOrdersTotal(Magic_Number)<_cur_total){
                        nlot = CalculateLot2(numberOfLegs,increaseLLotBy);
                        Print("Lot Finding, Lot Size[",nlot,"]");
                    /*  }
                    // else{
                        prev_lot = mm.CalculatePositionSize(Magic_Number, SELL_LEG1);
                        nlot= prev_lot*increaseLLotBy;
                        prev_lot = nlot;
                        */
                     //}
                     ccode      = SELL_LEG1;
                     op_code    = REVERSAL_SELL;
                     bool res   = Revised_Sell(ccode,op_code,nlot);
                     if(res == true){
                        _cur_total +=1;   
                        Print("Leg EntryS: _cur_total[",_cur_total,"], isTotal[",isOrdersTotal(Magic_Number),"]");               
                     }
                     else{Print("Sell Order(Leg) Failed");}
                  }
                  //---------------------------------------------------------------------
                  else if( useGHedge==true &&(algo.Pattern_Point_Negative(pointsE, Magic_Number) == REVERSAL_SELL)&& scount==numberOfLegs)
                  {
                     double pre_lot,n_lot= 0.0;
                     int count , op_c;
                     bool leg1 = algo.isExist(Magic_Number,(string)SELL_LEG1,count,op_c,pre_lot);
                     bool hed  = algo.isExist(Magic_Number,(string)HEDGE_BUY,count,op_c,pre_lot);
                     bool leg2 = algo.isExist(Magic_Number,(string)SELL_LEG2,count,op_c,pre_lot);
                     if(leg1== true && leg2 == true){
                        n_lot = mm.CalculatePositionSizeHedge(Magic_Number,SELL_LEG2);
                        //Print("_nLots[",n_lot,"]");
                     }
                     else if(leg1==true && hed ==false && leg2== false){
                        n_lot = mm.CalculatePositionSizeHedge(Magic_Number,SELL_LEG1);
                       // Print("_nLots[",n_lot,"]");
                     }
                     Print("_nLots[",n_lot,"]");
                     prev_lot = n_lot;
                     ccode    = HEDGE_BUY;
                     op_code  = DIRECTIONAL_BUY;
                     bool res = Revised_Buy(ccode,op_code,n_lot);
                     if(res == true){
                      _cur_total += 1;
                      }                   
                  }
				}
				  else if(algo.OrderOperationCode(Magic_Number) == HEDGE_BUY)
				  {
                  
				  }
               
            }        
         //--------------------------------------------------------------------------------------
        
       
	  if(IsNewBar())
         {
            int ccode = FAIL;
            int tcode = FAIL;         
            tcode = algo.isSignalCandleRev(_strat_type,ccode);
            if(useHedge == true && isOrdersTotal(Magic_Number) < 2)
            {
               if(!StringCompare((string)ccode,(string)algo.OrderOperationCode(Magic_Number))==0)
               {
                  if((tcode == DIRECTIONAL_BUY||tcode==REVERSAL_BUY)&&(algo.OrderOperationCode(Magic_Number)==FAIL))
                  { 
                     if((LR_Flag == true || mm.isConsequtive(ccode,Magic_Number)==false)&& tcode == REVERSAL_BUY){             
                        Print("Buy Alert Direction Code[",tcode,"]")                   ;
                        Print("Buy Alert C Code[",ccode,"]")                           ;
                        bool res = Revised_Buy(ccode,tcode)                      ;
                        LR_Flag  = false                                               ;
                     }
                     else if(tcode == DIRECTIONAL_BUY)
                     {
                        bool res = Revised_Buy(ccode,tcode)                      ;
                     }
                  }
                  else if((tcode == DIRECTIONAL_SELL||tcode==REVERSAL_SELL)&&(algo.OrderOperationCode(Magic_Number)==FAIL))
                  {     
                     if((LR_Flag == true || mm.isConsequtive(ccode,Magic_Number)==false) && tcode == REVERSAL_SELL){
                        Print("Sell Alert Direction Code[",tcode,"]")                  ;
                        Print("Sell Alert C Code[",ccode,"]")                          ;
                        bool res = Revised_Sell(ccode,tcode)                     ;
                        LR_Flag  = false                                               ;
                     }
                     else if(tcode == DIRECTIONAL_SELL)
                     {
                        bool res = Revised_Sell(ccode,tcode)                      ;
                     }
                  }
               }  
            }
            else if(useHedge == false)
            {}
         }
      } 
      //-------------------------------------------------------------  
      else if(isOrdersTotal(Magic_Number)<1){
         if(IsNewBar())
         {
            int ccode = FAIL;
            int tcode = FAIL;         
            tcode = algo.isSignalCandleRev(_strat_type,ccode);
            
            //Grid First Entry       
            if(useGridding == true)
            { 
               Comment("EA Started. MG.NO[",Magic_Number,"]");
               int op_code=FAIL;
               op_code = algo.isSignalCandleRev(_strat_type,ccode);
               //op_code = DIRECTIONAL_BUY;   //Uses Legacy Signals
               if((op_code == DIRECTIONAL_BUY||op_code==REVERSAL_BUY))
               {
                  ccode        = BUY_LEG1    ;
                  double lot   = startLot    ;
                  prev_lot     = startLot    ;
                  //-------------------------
                  bool res = Revised_Buy(ccode, op_code, lot);
                  if(res == true){
                     _cur_total = 1;
                     Print("First EntryB: _cur_total[",_cur_total,"], isTotal[",isOrdersTotal(Magic_Number),"]");
                  }
               } 
               else  if((op_code == DIRECTIONAL_SELL||op_code==REVERSAL_SELL))
               {
                  Print("Grid Sell");
                  ccode        = SELL_LEG1   ;
                  double lot   = startLot    ;
                  prev_lot     = startLot    ;
                  //-------------------------
                  bool res = Revised_Sell(ccode, op_code, lot);
                  if(res == true){
                     _cur_total = 1;
                     Print("First EntryS: _cur_total[",_cur_total,"], isTotal[",isOrdersTotal(Magic_Number),"]");
                  }
               } 
            }
            //---------------------------------------------------------------------------------------------------------------
         else if(useGridding == false){   
               if((tcode == DIRECTIONAL_BUY||tcode==REVERSAL_BUY)&&(algo.OrderOperationCode(Magic_Number)==FAIL))
               { 
                  if((LR_Flag == true || mm.isConsequtive(ccode,Magic_Number)==false)&& tcode == REVERSAL_BUY){             
                     Print("Buy Alert Direction Code[",tcode,"]")                   ;
                     Print("Buy Alert C Code[",ccode,"]")                           ;
                     bool res = Revised_Buy(ccode,tcode)                            ;
                     LR_Flag  = false                                               ;
                  }
                  else if(tcode == DIRECTIONAL_BUY)
                  {
                     bool res = Revised_Buy(ccode,tcode)                      ;
                  }
               }
               else if((tcode == DIRECTIONAL_SELL||tcode==REVERSAL_SELL)&&(algo.OrderOperationCode(Magic_Number)==FAIL))
               {  
                  Print("Noraml Sell");   
                  if((LR_Flag == true || mm.isConsequtive(ccode,Magic_Number)==false) && tcode == REVERSAL_SELL){
                     Print("Sell Alert Direction Code[",tcode,"]")                  ;
                     Print("Sell Alert C Code[",ccode,"]")                          ;
                     bool res = Revised_Sell(ccode,tcode)                     ;
                     LR_Flag  = false                                               ;
                  }
                  else if(tcode == DIRECTIONAL_SELL)
                  {
                     Print("Sell Direction");
                     bool res = Revised_Sell(ccode,tcode)                      ;
                  }
               }
            }                  
         }
     }//Print("Total Orders[",isOrdersTotal(Magic_Number),"]");
   }
  }
//+------------------------------------------------------------------+
bool IsNewBar()
  {
   static datetime RegBarTime=0;
   datetime ThisBarTime=Time[0];
   if(ThisBarTime==RegBarTime)
     {
      return false;
     }
   else
     {
      RegBarTime=ThisBarTime;
      return true;
     }
  }
bool Buy(int strat,int rt_Code)
{
    string comment = (string)strat+""+(string)rt_Code;
    double tp =0.0, sl =0.0;
    double lot = mm.CalculatePositionSize(lotType,LotSize,_risk);
    mm.PlaceOrder(OP_BUY,lot,TP_Type,TP_Value,SL_Type,SL_Value,Magic_Number,(int)comment);
    return false;
}
bool Sell(int strat,int rt_Code)
{
    string comment = (string)strat+""+(string)rt_Code;
    double tp =0.0, sl =0.0;
    double lot = mm.CalculatePositionSize(lotType,LotSize,_risk);
    mm.PlaceOrder(OP_SELL,lot,TP_Type,TP_Value,SL_Type,SL_Value,Magic_Number,(int)comment);
   return false;
}

bool Revised_Sell(int strat, int rt_Code, double _nlot)
{
   string comment = (string)strat;
   double tp =0.0, sl =0.0;
   //double lot = mm.CalculatePositionSize(lotType,LotSize,_risk);
   if     ((strat == SELL_LEG1 || strat == HEDGE_SELL)&&(rt_Code == DIRECTIONAL_SELL || rt_Code == REVERSAL_SELL))
   {        
      mm.PlaceOrder(OP_SELL,_nlot,TP_Type3,TP_Value3,SL_Type3,SL_Value3,Magic_Number,(int)comment);
      return true;
   }        
   else if((strat == SELL_LEG2 || strat == HEDGE_SELL)&& (rt_Code == DIRECTIONAL_SELL || rt_Code == REVERSAL_SELL))
   {
      mm.PlaceOrder(OP_SELL,_nlot,TP_Type3,TP_Value3,SL_Type3,SL_Value3,Magic_Number,(int)comment); 
      return true;  
   }
   else if (rt_Code == DIRECTIONAL_SELL && strat != SELL_LEG1 && strat != SELL_LEG2  ){
       mm.PlaceOrder(OP_SELL,_nlot,TP_Type1,TP_Value1,SL_Type1,SL_Value1,Magic_Number,(int)comment);
       return true;
   }
   else if(rt_Code == REVERSAL_SELL && strat != SELL_LEG1 && strat != SELL_LEG2  ){
       mm.PlaceOrder(OP_SELL,_nlot,TP_Type,TP_Value,SL_Type,SL_Value,Magic_Number,(int)comment);   
       return true;
   }
   return false;
}
bool Revised_Buy(int strat, int rt_Code)
{
   string comment = (string)strat;
   double tp =0.0, sl =0.0;
   double lot = mm.CalculatePositionSize(lotType,LotSize,_risk);
   if     (rt_Code == DIRECTIONAL_BUY)
   {       
      mm.PlaceOrder(OP_BUY,lot,TP_Type1,TP_Value1,SL_Type1,SL_Value1,Magic_Number,(int)comment);
      return true;
   }        
   else if(rt_Code == REVERSAL_BUY)
   {        
      mm.PlaceOrder(OP_BUY,lot,TP_Type,TP_Value,SL_Type,SL_Value,Magic_Number,(int)comment); 
      return true;  
   }         
   return false;
}
bool Revised_Buy(int strat, int rt_Code, double n_lot)
{
   string comment = (string)strat;
   double tp =0.0, sl =0.0;
  // double lot = mm.CalculatePositionSize(lotType,LotSize,_risk);
   if     (rt_Code == DIRECTIONAL_BUY && strat != BUY_LEG1 && strat != BUY_LEG2 )
   {       
      mm.PlaceOrder(OP_BUY,n_lot,TP_Type1,TP_Value1,SL_Type1,SL_Value1,Magic_Number,(int)comment);
      return true;
   }        
   else if(rt_Code == REVERSAL_BUY && strat != BUY_LEG1 && strat != BUY_LEG2)
   {        
      mm.PlaceOrder(OP_BUY,n_lot,TP_Type,TP_Value,SL_Type,SL_Value,Magic_Number,(int)comment);   
      return true;
   }
   else if((strat == BUY_LEG1 || strat == HEDGE_BUY) && (rt_Code== DIRECTIONAL_BUY ||rt_Code == REVERSAL_BUY )) {
      mm.PlaceOrder(OP_BUY,n_lot,TP_Type3,TP_Value3,SL_Type3,SL_Value3,Magic_Number,(int)comment);
      return true;
   }
   else if((strat == BUY_LEG2 || strat == HEDGE_BUY) && (rt_Code == DIRECTIONAL_BUY ||rt_Code == REVERSAL_BUY )) {
      mm.PlaceOrder(OP_BUY,n_lot,TP_Type3,TP_Value3,SL_Type3,SL_Value3,Magic_Number,(int)comment);
      return true;
   }        
   return false;
}
bool Revised_Sell(int strat, int rt_Code)
{
   string comment = (string)strat;
   double tp =0.0, sl =0.0;
   double lot = mm.CalculatePositionSize(lotType,LotSize,_risk);
   if     (rt_Code == DIRECTIONAL_SELL)
   {        
      mm.PlaceOrder(OP_SELL,lot,TP_Type1,TP_Value1,SL_Type1,SL_Value1,Magic_Number,(int)comment);
      return true;
   }        
   else if(rt_Code == REVERSAL_SELL)
   {
      mm.PlaceOrder(OP_SELL,lot,TP_Type,TP_Value,SL_Type,SL_Value,Magic_Number,(int)comment);   
      return true;
   }
   return false;
}
int PreviousOrder()
{
   if(OrdersTotal()>0)
   {
      if(OrderSelect(0,SELECT_BY_POS,MODE_TRADES)>0)
      {
         if(OrderSymbol()==Symbol() && OrderMagicNumber()==Magic_Number)
         {
            return OrderType();
         }
      }
   }
   else{
      if(OrderSelect(0,SELECT_BY_POS,MODE_HISTORY)>0)
      {
         if(OrderSymbol()==Symbol() && OrderMagicNumber()==Magic_Number)
         {
            return OrderType();
         }
      }   
   }
   return FAIL;
}
bool CheckLR()
{
   double lr  = ind.iLR(1,LR)      ;
   int opcode = PreviousOrder()    ;
   if     (opcode == OP_BUY )   
   {
      if(Close[1]>lr) return true  ;
      else            return false ;      
   }
   else if(opcode == OP_SELL)
   {
      if(Close[1]<lr) return true  ;   
      else            return false ;
   }
   return                     false;
}
double CalculateLot()
{
   double lotsize=0.0;
   int total = OrdersTotal();
   for(int i= total-1; i >0 ; i --)
   {
     
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
      {
         lotsize=OrderLots();
         if(legIncreaseDecrease == INCREASE)
         {
           lotsize= lotsize*increaseLLotBy;
           return lotsize;
         }
         else if(legIncreaseDecrease == DECREASE)
         {
            lotsize= lotsize*decreaseLLotBy;
            return lotsize;
         }
         else if(legIncreaseDecrease == SAME)
         {
            lotsize= lotsize;
            return lotsize;
         }         
      }
   
   }
   return lotsize;
   
}
double CalculateLot2()
{
   double lotsize=0.0;
   int    tick=0     ;
   int total = OrdersHistoryTotal();   
   if(OrderSelect(total-1,SELECT_BY_POS,MODE_HISTORY)>0){
      if(OrderMagicNumber() == Magic_Number && OrderSymbol() == Symbol()){
         lotsize=OrderLots();
         tick = OrderTicket();
      }                  
   }
   Print("Lot Size2[",lotsize,"], Ticket[",tick,"]");   
   return lotsize;
   
}
double CalculateLot2(int leg, int factor)
{
   double array1[];
   double array2[];
   ArrayResize(array1, 100,0 );
   ArrayResize(array2, 100,0 );
   double prev = startLot;
   for (int ii =0 ; ii< leg; ii++){
      array1[ii] = prev;
      prev = prev* factor;
      ArrayResize(array1,ArraySize(array1)+1);
   }
   double lotsize=0.0;
   int    tick=0     ;
   int total = OrdersTotal();
   for (int ii = 0;ii<total; ii++){
      if(OrderSelect(ii,SELECT_BY_POS,MODE_TRADES)>0){
         if(OrderMagicNumber() == Magic_Number && OrderSymbol() == Symbol()){            
               array2[ii] = OrderLots();
               ArrayResize(array2,ArraySize(array2)+1);
               Print("OrderLots[",OrderLots(),"]");
         }
      }     
   } 
   bool found = false; 
   for(int ii =0; ii<ArraySize(array1); ii++){
      for(int jj=0; jj<ArraySize(array2);jj++){
         if(array1[ii]!=array2[jj]){
            found =false;
            lotsize =array1[ii];
            //Print("Lot Size[",lotsize,"]");
            }         
         else if(array1[ii]==array2[jj]){
            Print("Found[",array1[ii],"]");
            found = true;
            break;
         }
       }
      if(found == false){
         return lotsize;
      }         
   }   
   return lotsize;
   
}
int isOrdersTotal(int mg)
{
   int count =0;
   int total = OrdersTotal();
   for(int i = 0 ;i<total;i++){
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)>0){
         if(OrderMagicNumber()==mg && OrderSymbol()== Symbol()){
               count+=1;               
         }      
      }
   }
   return count;
}
bool OrderOperationCode(int magic, int op){
    int total = OrdersTotal()                          ;
    int opCode = FAIL                                  ;
    if(total<1)return FAIL                             ;
    for(int i=0; i<total;i++)
    {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true)
      {
        // Print("Checking for order[",op,"]");
         if((OrderMagicNumber()==magic ) && (OrderSymbol()==Symbol()) )
         {
            opCode = (int) OrderComment()              ;
            if(opCode == op) return true;
         }
       }
     }
    return false                                      ;
}