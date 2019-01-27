//+------------------------------------------------------------------+
//|                                              SyntheticSpread.mq4 |
//|                 Copyright 2018, QuantSoftware.net, Zobad Mahmood |
//|                                    https://www.quantsoftware.net |
//|Brief:
//| Triangular arbitrage based on the price ratio of three pairs.
//| Will include:
//|     Issue with Sl value(Fixed). Parameter needed open price as well
//|     -Calculate lot size for different pair(pending
//|     -Tp on mid of pair spread(pending)
//|     -sl on Equity (pending)
//|     -grid on Equity loss*multiply(both positive and negative):(fixed)
//|         so if our order makes loss in$ for a specific ammount we will open a new leg.
//|         the next leg will be at Equity at which previous leg was opened * multiply(pending)
//|     -cut and reverse(pending)
//|     - Normal Breakin entry on Lead Pair
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, QuantSoftware.net, Zobad Mahmood"
#property link      "https://www.quantsoftware.net"
#property version   "1.00"
#property strict


//----------------------------------
   #include "EntrySignal.mqh"
   #include "MoneyManagement.mqh"
   #include "Indicators.mqh"
   
   
   EntrySignal     *algo ;
   MoneyManagement *mm   ;
   Indicators      *ind  ;
//-----------------------------------------
   enum LotType{
      MANUAL = 0,
      AUTO    = 1,
   };
enum Take_Profit_Type{
   
   FIXED = 0,
   VOLATILITY = 1,
   MID_BB = 2,
   OPP_BAND = 3,
   
};
enum GridDirection{
   PositiveGrid = 1,
   NegativeGrid = -1,

};
enum Strat_typeII
            {
               _PAIR_REVERSAL = 10,   //Pair Reversal
               _PAIR_DIRECTIONAL = 9, //PairM Directional
               _PAIR_MREVERSAL = 11, //PairM Reversal *not working
               _DIRECTIONAL = 4,  //Directional
               _REVERSAL    = 5,  //Reversal
               //BOTH        = 1,  //Dir&Rev
               //ST_DEV_C2   = 2,  //Standard Deviation 2
               //ST_DEV_C3   = 3,  //Standard Deviation 3
               _BREAKIN     = 6,  //Break in *not working
               _DIRECTIONAL_Range = 7,  //Directional Volatility *not working
               _REVERSAL_Range    = 8,  //Reversal Volatility *not working      
            };
            
int                    buy_counter=0;
int                    sell_counter=0;
int                    _legCount = 0 ;
double                 prevThresholdLvl = 0.0;
int                     _count=0;
int                    _ticket;
double                 _tp;
double                 _sl;
int                    _opType;
double                 _op_price;
 //-----------------------------------------           
            
extern int              Magic_Number       = 1         ;             //Magic Number 
bool             useLegacy          = false     ;             //Use Legacy Entry Signal
string          set="----------Consecutive Losses--------------";//Consecutive Losses Settings
bool                    useConsecutive     = false     ;             //Use Consecutive Loss
int                     noConsqLossAllowed = 3         ;             //Consecutive Losses Allowed
double                  percentReduction   = 5         ;             //Lot Size Percent Reduction
extern string          setLot=     "-------Lot Setting -------"       ;
extern LotType          lotType            = MANUAL      ;             //Lot Type
double           _risk              = 0.02       ;             //%Available Balance::Lot
extern double           LotSize            = 1      ;             //Position:: Lot LeadPair(Manual)
extern double           LotSizeX            = 5      ;             //Position:: Lot FollowerPair1(Manual)
extern double           LotSizeZ            = 1      ;             //Position:: Lot FollowerPair2(Manual)
extern string          order1=     "-------Order -------"             ;             //Order 1 Settings
bool                   order1Open         =  false    ; 
extern Strat_typeII      _strat_type        = _PAIR_REVERSAL ;       //Strategy:: Type      
extern bool             useStrategy1       = true      ;             //Strategy:: Use Strategy
bool                    useHedge           = false     ;             //Strategy:: Use Hegde 
extern string           pairX              = "US30"    ;             //LeadPair
extern string           pairY              = "US500"   ;             //FollowerPair1
extern string           pairZ              = "USNDX"   ;             //FollowerPair2
bool             visible            = false      ;

extern Take_Profit_Type TP_Type            = VOLATILITY;             //TP:: Type
extern Take_Profit_Type SL_Type            = VOLATILITY;             //SL:: Type
extern double           TP_Value           =  3.0      ;             //TP:: Volatility/Fixed(Points)
extern double           SL_Value           =  3.0      ;             //SL:: Volatility/Fixed(Points)
double           _range             = 2.5       ;             
 int              leg                = 6         ;
 double           multiply           = 2.5       ;
extern string          GridSet   = "------Grid Settings-----------------";
extern bool            useGrid   =  false;
extern GridDirection   gridDirection = NegativeGrid;
extern int             gridMultiply  = 2;
extern int             gridLeg       = 3;
extern bool             EQ_Based           = true      ;             //Use Equity Based TP
extern bool             useGridStop        = true     ;             //Us Equity Based SL
extern double           _profitTarget      = 1000      ;             //Profit Target
extern double           _stopLevel         = -500.0    ;             //Stop Out Level
int              _timegap1          = 31        ;             //Order 1 time gap(in mins)
double                 _highestStop1                  ;
double                 _lowestStop1                   ;
bool                   LR_Flag            = false     ;      
double                 prev_lot           =0.0        ;
int                    _cur_total         = 0         ;
bool                   startFlag          = false     ;
extern string          prSet=     "-------PR Settings -------"             ;             

string prpath = "price_ratio_0.0.5.EX4";
extern   int    prSignalMethod   = MODE_SMA;
extern    int    prSignalSMA      = 14;
   int    prSignalSMA2     = 100;
   int    prlagPeriod      = 8;
extern   int    prBandsPeriod    = 14;
extern   int    prBandsDeviation = 2;
//------------------------------------------------------
datetime expiry = D'2020.06.06 00:00';
bool bExpiryAlertDelieverd = false;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   expiry = D'2020.06.06 00:00';
   bExpiryAlertDelieverd = false;
   startFlag = true ;
   algo = new EntrySignal(9,9)    ;
   mm   = new MoneyManagement();
   ind   = new Indicators(9,9)    ;
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
   Comment("Lead: "+pairX+"|Follower1:"+pairY+"|Follower2"+pairZ+"\ntp["+(string)_tp+"] sl["+(string)_sl+"]\nprevThreshold["+(string)prevThresholdLvl+"], leg["+IntegerToString(_legCount)+"], ");
   int profitOrLoss = 0;
   if(isOrdersTotal(Magic_Number)==0){   
   
      //No open order: Check entry signal and place order accordingly
      if(EntrySignalPair( _strat_type, OP_BUY) ){
                                                   PlaceOrderPair(OP_BUY,OP_SELL,OP_SELL,"Spread Buy");
                                                   Print("Spread Buy");
                                                   _legCount = 1;
                                                   prevThresholdLvl = ((gridDirection == PositiveGrid)? _profitTarget:  _stopLevel);
                                                   if(prevThresholdLvl == 0.0)Print("Error Assigning value: prevTheshold");
                                                }
      else if(EntrySignalPair( _strat_type, OP_SELL) ){
                                                   PlaceOrderPair(OP_SELL,OP_BUY,OP_BUY,"Spread Sell");
                                                   Print("Spread Sell");
                                                   prevThresholdLvl = ((gridDirection == PositiveGrid)? _profitTarget:  _stopLevel); 
                                                   _legCount = 1;
                                                   if(prevThresholdLvl  == 0.0)Print("Error Assigning value: prevTheshold");
                                                }
   }
   
   
   else if(isOrdersTotal(Magic_Number) > 0){
   
      //If orders open- Check if their Tp/Sl level has reached and close order accordingly
      double _Ask =MarketInfo(pairX,MODE_ASK), lotX, profitX;
      double _Bid =MarketInfo(pairX,MODE_BID);
      int op =0;
      double stThresh = 0;
      //Check on tp and sl the gridDirection
      stThresh = (gridDirection == PositiveGrid?_profitTarget: _stopLevel);
      //Print("Grid Threshold",stThresh);
      LastOrderOperation(pairX,op,lotX,profitX);
      if(_tp > 0 && _sl>0){
            if(op == OP_BUY){
                           if(MarketInfo(pairX,MODE_ASK) >= _tp && gridDirection != PositiveGrid){mm.CloseAllOrders(Magic_Number);/*Close All Orders*/}
                           if(MarketInfo(pairX,MODE_BID) <= _sl && gridDirection != NegativeGrid){mm.CloseAllOrders(Magic_Number);}/*Close All Orders*/
                           if(useGrid && isGridTrigger(gridDirection,Magic_Number,pairX,stThresh,gridMultiply,prevThresholdLvl)){
                              if(legOpen(Magic_Number,pairX) < gridLeg ){ 
                                 PlaceOrderPair(OP_BUY,OP_SELL,OP_SELL,"Spread Buy");
                                 _legCount++;
                                 prevThresholdLvl = clalculateEquityGridII(Magic_Number,pairX, gridDirection,stThresh,gridMultiply);
                                 Print("Spread Buy-Grid[leg: ",IntegerToString(_legCount),"], PrevThreshold["+DoubleToString(prevThresholdLvl)+"]");}
                           }
            }
            else if(op == OP_SELL){
                           if(gridDirection != NegativeGrid && MarketInfo(pairX,MODE_ASK) >= _sl){mm.CloseAllOrders(Magic_Number);/*Close All Orders*/}
                           if(gridDirection != PositiveGrid && MarketInfo(pairX,MODE_BID)<= _tp){mm.CloseAllOrders(Magic_Number);/*Close All Orders*/}
                           if(useGrid && isGridTrigger(gridDirection,Magic_Number,pairX,stThresh,gridMultiply,prevThresholdLvl)){
                              if(legOpen(Magic_Number,pairX)<leg){
                                 PlaceOrderPair(OP_SELL,OP_BUY,OP_BUY,"Spread Sell");
                                 _legCount++;
                                 prevThresholdLvl = clalculateEquityGridII(Magic_Number,pairX, gridDirection,stThresh,gridMultiply);
                                 Print("Spread Sell-Grid[leg: ",IntegerToString(_legCount),"], PrevThreshold[",DoubleToString(prevThresholdLvl),"]");
                                }
                           }
            } 
      }  
      //Use Equity stop based on grid direction. 
      if(gridDirection == PositiveGrid)mm.EquityBasedClose(false,_profitTarget,useGridStop,_stopLevel,Magic_Number,profitOrLoss);
      else if(gridDirection == NegativeGrid)mm.EquityBasedClose(EQ_Based,_profitTarget,false,_stopLevel,Magic_Number,profitOrLoss);
      else mm.EquityBasedClose(EQ_Based,_profitTarget,useGridStop,_stopLevel,Magic_Number,profitOrLoss);
   }
   
  }
//+------------------------------------------------------------------+
int isOrdersTotal(int mg)
{
   int count =0;
   int total = OrdersTotal();
   for(int i = 0 ;i<total;i++){
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)>0){
         if(OrderMagicNumber()==mg /*&& OrderSymbol()== Symbol()*/){
               count+=1;               
         }      
      }
   }
   return count;
}
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
bool PlaceOrderPair( int op_x, int op_y,int op_z,string comment)
{
  // double _tp =0.0, _sl = 0.0;
   int ATR_period = 14;
   double lotX = LotSize,lotY = LotSizeX ,lotZ =LotSizeZ;//Need to calculate this autmatically
   PlaceOrderPairsHidden(pairX,pairY,pairZ,op_x,op_y,op_z,lotX,lotY,lotZ,Magic_Number,comment);
   if(op_x==OP_BUY)_op_price=MarketInfo(pairX,MODE_ASK);
   else if(op_x == OP_SELL)_op_price =MarketInfo(pairX,MODE_BID);
   if(_strat_type == _PAIR_REVERSAL)
   {
      if(!TP_Type == MID_BB)
      {
         _tp = mm.CalculateTP(pairX,op_x,TP_Type,TP_Value);
         _sl = mm.CalculateSL(pairX,op_x,_op_price,SL_Type,SL_Value);
         Print("tp[",(string)_tp,"] sl[",(string)_sl,"]");
      }
      else
      {
         
      _sl = mm.CalculateSL(pairX,op_x,_op_price,SL_Type,SL_Value);
      _tp = mm.CalculateTP(pairX,op_x,TP_Type,TP_Value);
      Print("tp[",(string)_tp,"] sl[",(string)_sl,"]");
      }
      _count++;   
   }
   else if(_strat_type == _PAIR_DIRECTIONAL)
   {
      if(!TP_Type == MID_BB)
      {
         _tp = mm.CalculateTP(pairX,op_x,TP_Type,TP_Value);
         _sl = mm.CalculateSL(pairX,op_x,_op_price,SL_Type,SL_Value);
         Print("tp[",(string)_tp,"] sl[",(string)_sl,"]");
      }
      else
      {
         
      _sl = mm.CalculateSL(pairX,op_x,_op_price,SL_Type,SL_Value);
      _tp = mm.CalculateTP(pairX,op_x,TP_Type,TP_Value);
      Print("tp[",(string)_tp,"] sl[",(string)_sl,"]");
      }
      _count++;   
   }   
   
   return false;
   //return ();
}
bool PlaceOrderPairsHidden(string pair_X, string pair_Y, string pair_Z,int opX, int opY,int opZ, double lotX, double lotY,double lotZ, int mg, string comment)
{
   int ticketY =0;
   int ticketX=0;
   int ticketZ=0;
   int Slippage =33;
   double pY =0.0; double pX =0.0,pZ=0.0;
   if(opY==OP_BUY)pY=MarketInfo(pair_Y,MODE_ASK);
   else if(opY == OP_SELL)pY=MarketInfo(pair_Y,MODE_BID);
   if(opX==OP_BUY)pX=MarketInfo(pair_X,MODE_ASK);
   else if(opX == OP_SELL)pX=MarketInfo(pair_X,MODE_BID);
   if(opZ==OP_BUY)pZ=MarketInfo(pair_Z,MODE_ASK);
   else if(opZ==OP_SELL)pZ=MarketInfo(pair_Z,MODE_BID);
   Print("pY[",pY,"] pX[",pX,"]");
   ticketX = OrderSend(pair_X,opX,lotX,pX,Slippage,0,0,comment,mg,0,Yellow);
   
   ticketY = OrderSend(pair_Y,opY,lotY,pY,Slippage,0,0,comment,mg,0,Yellow);
   
   ticketZ = OrderSend(pair_Z,opZ,lotZ,pZ,Slippage,0,0,comment,mg,0,Yellow);
   Print("TicketX[",ticketX,"] TicketY[",ticketY,"] TicketZ[",ticketZ,"]");
   
   if(!mm.Ticket_Check(ticketY)) return false;
   if(!mm.Ticket_Check(ticketX))return false;
   if(!mm.Ticket_Check(ticketZ))return false;
 
   return true;
}


int CutAndReverse(string y, string x, string z){
   int op_y=0,op_x=0;
   double lot_x=0.0,lot_y=0.0, profitX=0.0, profitY=0.0;
   int value=isOrdersTotal(Magic_Number);    
  // Print("Value[",value,"]");  
   if(value==0){
      Print("Cut and reverse value = 0");      
      if(_count<leg){
         LastOrderOperation(y,op_y, lot_y,profitY);
         LastOrderOperation(x,op_x, lot_x, profitX);
         Print("lot_y[",lot_y,"] lot_x[",lot_x,"]");
         
         if(profitY+profitX<0)
         {
           if(mm.PlaceOrderPairsHidden(y,x,op_x,op_y,lot_y*multiply,lot_x*multiply,Magic_Number,"Pair Trading-c"))
           {/*if(isOrdersTotal(Magic_Number)>1)*/ 
               _tp = NormalizeDouble( mm.CalculatePairTP(y,x,14,op_y,TP_Type,TP_Value),(int)MarketInfo(y,MODE_DIGITS));
               _sl = NormalizeDouble( mm.CalculatePairSL(y,x,14,op_y,SL_Type,SL_Value),(int)MarketInfo(y,MODE_DIGITS));
               _count++;               
            }else  Print("Error: Unable to Reverse");
         
         }else
         {
            //Profit. Reset Counter
            _tp = 0.0;
            _sl =0.0;
            _count = 0;
         } 
      }
       else  return FAIL;
    } 
    else if(value == 1){
      //Close Order
     if( mm.CloseOrder(Magic_Number,x)) return 1;
     else if( mm.CloseOrder(Magic_Number,y)) return 1;
     else return -1;
    }               
   return(0);
}
void LastOrderOperation(string symbol, int & operation, double &lot, double & profit){
   for(int i=OrdersHistoryTotal()-1; i>0; i--)       //Cycle for all orders..
   {                                        //displayed in the terminal
        if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY))//If there is the next one
        { 
            if(OrderMagicNumber() == Magic_Number && OrderSymbol()==symbol)
            {
               operation = OrderType();
               lot =OrderLots();
               profit = OrderProfit();   
               break;                                   
            }
            else continue;
         }
    }

}
int IsSignal(int strat, double range){
   //buyDir=1, buyRev=11,sellDir-1,sellRev=-11, fail =FAIL
   double ma = ind.iBB(1,MODE_MAIN);
   double _point= MarketInfo(Symbol(),MODE_POINT);
   double atr = ind.iAtr(1);
   double nrange = atr * range;
   double crange = High[1]- Low[1];
  //Print("Range Crossed");
      if(strat == _DIRECTIONAL_Range){
     // Print("Directional");
         if(crange > nrange)
         {
              if(Open[1]< ma && Close[1]>ma){Print("Directional Buy");return(DIRECTIONAL_BUY);}
              else if(Open[1]>ma && Close[1]<ma){Print("Directional Sell");return(DIRECTIONAL_SELL);}
         }
         else return FAIL;         
      }
      else if(strat ==_REVERSAL_Range){
         //Print("Reversal");
         if(Open[1]>ma && Close[1]<ma){Print("Reversal Buy");return(REVERSAL_BUY);}//Buy("Reversal");}
         else if(Open[1]< ma && Close[1]>ma){Print("Reversal Sell");return(REVERSAL_SELL);}
      }
      else if(strat == DIRECTIONAL){
         int ccode = algo.Directional();
         if(ccode == DIRECTIONAL_BUY || ccode== DIRECTIONAL_SELL)return ccode;
      }
      else if(strat == REVERSAL){
         int ccode = algo.Reversal();
         if(ccode == REVERSAL_BUY || ccode== REVERSAL_SELL)return ccode;
      }
      else if(strat == _BREAKIN){
         int ccode = algo.Pattern_Breakin();
         if( ccode == REVERSAL_BUY || ccode == REVERSAL_SELL) {Print("Breakin");return ccode;   }
      }
     /* else if(strat == _PAIR_DIRECTIONAL){
         int ccode = algo.PR_Directional(pairY,pairX);
         if(ccode == DIRECTIONAL_BUY  || ccode == DIRECTIONAL_SELL ){Print("Pair Breakin"); return ccode;}
      
      }
      else if(strat == _PAIR_REVERSAL){
         int ccode = algo.PR_Reversal(pairY,pairX);
         if(ccode == REVERSAL_BUY  || ccode == REVERSAL_SELL ){Print("Pair Breakout"); return ccode;}
      }*/
      return FAIL;   
}
void CalculatePairLot(string y, string x){
   //find tick value
   double y_tickvalue = MarketInfo(y,MODE_TICKVALUE);
   double x_tickvalue = MarketInfo(x,MODE_TICKVALUE);
   //find tick size
   double y_ticksize = MarketInfo(y,MODE_TICKSIZE);
   double x_ticksize = MarketInfo(x,MODE_TICKSIZE);
   //min lot step
   double y_lotstep = MarketInfo(y,MODE_LOTSTEP);
   double x_lotstep = MarketInfo(x,MODE_LOTSTEP);
   //min lot size allowed
   double y_minlot = MarketInfo(y,MODE_MINLOT);
   double x_minlot = MarketInfo(x,MODE_MINLOT);
   //---------------------------------------
   //Check how to equalize lot size
   //work in progress... 

}

bool EntrySignalPair(int strat, int op){

   int bupper =4, blower =3, bspread =0, bmid=1;
   double spread = iPriceSpread(pairX,pairY,bspread,0), spreadZ= iPriceSpread(pairX,pairZ,bspread,0), spreadMid= iPriceSpread(pairX,pairZ,bmid,0);
   double upper  = iPriceSpread(pairX,pairY,bupper,0), upperZ  = iPriceSpread(pairX,pairZ,bupper,0);
   double lower  = iPriceSpread(pairX,pairY,blower,0), lowerZ  = iPriceSpread(pairX,pairZ,blower,0);
   if(strat == _PAIR_DIRECTIONAL){
      
      /*---------------
      if((spread >= upper || spreadZ>= upperZ) ){ if(op == OP_BUY )return true;}
      if((spread <= lower || spreadZ <= lowerZ)){if(  op == OP_SELL) return true;}
   
   }
   else if(strat == _PAIR_REVERSAL){
      if((spread >= upper || spreadZ>= upperZ) && op == OP_SELL){ return true;PlaceOrderPair(OP_SELL,OP_BUY,OP_BUY,"Spread Sell");Print("Spread Sell");}
      if((spread <= lower || spreadZ <= lowerZ) && op == OP_BUY){ return true;PlaceOrderPair(OP_BUY,OP_SELL,OP_SELL,"Spread Buy");Print("Spread Buy");}
   }*/
         if((spread >= upper && spreadZ>= spreadMid) ){ if(op == OP_BUY )return true;}
      if((spread <= lower && spreadZ <= spreadMid)){if(  op == OP_SELL) return true;}
   
   }
   else if(strat == _PAIR_REVERSAL){
      if((spread >= upper && spreadZ>= spreadMid) && op == OP_SELL){ return true;}
      if((spread <= lower && spreadZ <= spreadMid) && op == OP_BUY){ return true;}
   }
   
   return false;
}

double iPriceSpread(string x, string y, int bufferNo,int index){
   
   //bufferNo= 0 = spread, buff1 =mid
   // 4= upper, 3=lower
   
   double pr = iCustom(NULL,0,prpath,x,y,prSignalMethod,prSignalSMA,prSignalSMA2,prlagPeriod,prBandsPeriod,prBandsDeviation,bufferNo,index);
   return pr;

}
double CalculateSL(string x,int op, double openPrice  ,int    sl_type, double value)
{
   double sl    = 0.0                                           ;
   double atr   = 0.0                                     ;
   double point = MarketInfo(x,MODE_POINT)               ;
   int    digit = (int)MarketInfo(x,MODE_DIGITS)         ;
   double minsl = MarketInfo(x,MODE_STOPLEVEL)           ;
   minsl        = NormalizeDouble(minsl*point,digit)           ;
    atr= NormalizeDouble(iATR(x, 0,14,0),digit);
   double _Ask =MarketInfo(x,MODE_ASK);
   double _Bid =MarketInfo(x,MODE_BID);
   
   RefreshRates()                                               ;
   //--------------------------------------------
   if(op == OP_BUY)
   {
       switch(sl_type)
         {
            case 0:
               sl = _Bid - value*point                           ;
               Print("Case Fix:Stop Loss [",sl,"]")             ;
               break                                            ;
            case 1:
               sl = _Bid - atr*value                             ;
               Print("Bid[",_Bid,"]Case Volatility:Stop Loss [",sl,"]")      ;
               break                                            ;
             default :
               Print("Error in SL Type. [",sl_type,"]")         ;
               break                                            ;
          }
       if(openPrice-sl>=minsl)
           {
            sl = NormalizeDouble(sl,digit)                      ;
            Print("Stop Loss [",sl,"]")                         ;
           }
      if(openPrice-sl<minsl)
           {
            double toAdd = minsl+(55*point)                     ;
            sl           = openPrice-toAdd                      ; 
            sl           = NormalizeDouble(sl,digit)            ;
            Print("Small Stop Loss [",sl,"]")                   ;
           }   
   }
   else if(op==OP_SELL)
    {  
      switch(sl_type)
           {
             case 0:
                  sl = _Bid+ value*point                         ;
                  Print("Case Fix:Stop Loss [",sl,"]")          ;
                  break                                         ;
             case 1:
                  sl=_Bid+ atr*value                             ;
                  Print("Bid[",_Bid,"]Case Volatility:Stop Loss [",sl,"]")   ;
                  break                                         ;
           }       
         if(sl-openPrice>=minsl )
           {
            sl          = NormalizeDouble(sl,digit)             ;
            Print("Stop Loss [",sl,"]")                         ;
            }
         else if(sl-openPrice<minsl)
           {
            double toAdd = minsl+(7.0 *point)                   ;
            sl           = openPrice+toAdd                      ;
            sl           = NormalizeDouble(sl,digit)            ;
            Print("Small Stop Loss [",sl,"]")                   ;
           }
    }
    return sl                                                   ;
}


double CalculateTP(string x, int op,   int    tp_type, double value)
{
   double tp    = 0.0                                            ;
   //double atr   = i.iAtr(0)                                      ;
   double atr =0.0;
   int midBuffer = 1;
   int index=0;
   string y = pairY;
   double point = MarketInfo(x,MODE_POINT)                ;
   int    digit = (int)MarketInfo(x,MODE_DIGITS)          ;
   //double mid   = i.iBB(0,MODE_MAIN)                             ;//iBands(NULL,0,BB_Period,2,0,PRICE_CLOSE,MODE_MAIN,1);
    double mid = iPriceSpread(x,y,midBuffer, index);
    atr= NormalizeDouble(iATR(x, 0,14,0),digit);
   RefreshRates()                                                ;
   double _Ask =MarketInfo(x,MODE_ASK);
   double _Bid =MarketInfo(x,MODE_BID);
   //--------------------------------------------
   if(op == OP_BUY)
   {
      switch(tp_type)
        {
          case 0:
             tp = _Ask+ value*point                              ;
             Print("Case 0 fix: Tp[",tp,"]")                    ;
             break                                              ;
          case 1:
             tp = _Ask+ atr*value                                ;
             Print("Case 1 volatility: Tp[",tp,"]")                    ;
             break                                              ;
          case 2:
             Print("Mid Band: ",mid)                            ;
             tp = mid                                           ;
             Print("Case 3: mid Tp[",tp,"]")                    ;
             break                                              ;
          default :
             Print("Error in Tp Type. [",tp_type,"]")           ;
             break                                              ;
        }
   }
   else if (op == OP_SELL)
   {
      switch(tp_type)
        {
          case 0:
             tp = _Bid - value*point                             ;
             Print("Case 0: fix Tp[",tp,"]")                    ;
             break                                              ;
          case 1:
             tp = _Bid - atr*value                               ;
             Print("Case 1: volatility Tp[",DoubleToString(tp),"]")                    ;
             break                                              ;
          case 2:
             tp = mid                                           ;
             Print("Case 1: mid Tp[",DoubleToString(tp),"]")                    ;
             break                                              ;
        }   
   }
   return tp                                                    ;
}

//LegOpen(magic:int, symbol:string ):int
//Matches orders whose magic number and symbol matches and return order count
int legOpen(int magic, string symbol){
   int count =0;
   int total = OrdersTotal();
   for(int i = 0 ;i<total;i++){
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)>0){
         if(OrderMagicNumber()==magic && OrderSymbol()== symbol){
               count+=1;               
         }      
      }
   }
   return count;
}

//LegOpen(magic:int, symbol:string ):int
//Matches orders whose magic number matches and return order count
int legOpen(int magic){
   int count =0;
   int total = OrdersTotal();
   for(int i = 0 ;i<total;i++){
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)>0){
         if(OrderMagicNumber()==magic){ count+=1; }      
      }
   }
   return count;
}

//getEquity(): double return total equity for all open orders
double getEquity(){
   double equity =0;
   int total = OrdersTotal();
   for(int i = 0 ;i<total;i++){
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)>0){ equity+=OrderProfit();}
   }
   return equity;
}

//getEquity(): double return total equity open orders
//param: magic:int, symbol:string
double getEquity(int magic, string symbol){
   double equity =0;
   int total = OrdersTotal();
   
   for(int i = 0 ;i<total;i++){
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)>0){
         if(OrderMagicNumber()==magic && OrderSymbol()== symbol){
               equity+=OrderProfit();               
         }      
      }
   }
   return equity;
}

//getEquity(): double return total equity for open orders
//param: magic:int
double getEquity(int magic){
   double equity =0;
   int total = OrdersTotal();
   for(int i = 0 ;i<total;i++){
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)>0){
         //OrderMagicNumber==magic?equity+=OrderProfit()
         if(OrderMagicNumber()==magic){
               equity+=OrderProfit();               
         }      
      }
   }
   return equity;
}

//calculateEquityGrid(): returns threshold for next leg
//param: startThreshold:double, multiply:double, leg:int
//prev leg what is it?
//preleg + startThreshold? what if gridding on negative
//Instead if we calculate the amount to add, so: startThreshold * mult
double calculateEquityGrid(int direction,double startThreshold, double mult, double prevleg){
   double threshold = 0.0;
   if(direction == PositiveGrid) {threshold = (prevleg + startThreshold)*mult;Print("CEG[",DoubleToString(threshold),"]");}
   else{threshold = prevleg - startThreshold;Print("CEG[",DoubleToString(threshold),"]");}
   return threshold;
}
double clalculateEquityGridII(int magic,string pair,int direction , double startLvl, double mult)
{
   double _multiply = 0.0;
   double thresh = startLvl;
   int _leg = legOpen(magic,pair);
   for(int i = 2; i<=_leg ;i++){
         _multiply =thresh * mult; 
         thresh+= _multiply;
         Print("Thresh[",DoubleToString(thresh),"] count[",IntegerToString(i),"]");
         
   }
   Print("Thresh[",DoubleToString(thresh),"]");
   return thresh;
}
//return true if threshold value is hit
//param: direction: int, magic:int, symbol:string, stThresh:double, mult:double, prevleg:double
bool isGridTrigger(int direction,int magic, string symbol, double stThresh, double mult, double prevleg){
   //Check which direction for grid
   //Check how many legs open
   int legCount = legOpen(magic,symbol);
   //check equity threshold
   //double threshold = calculateEquityGrid(direction,stThresh,mult,prevleg);
   Print("legCount[",IntegerToString(legCount),"],threshold[",DoubleToString(prevleg),"]");
   //if positive grid:
   if(direction == PositiveGrid){  return(getEquity(magic)>=prevleg?true:false);}
   else if(direction == NegativeGrid) return(getEquity(magic)<prevleg?true:false);

   return false;
}

