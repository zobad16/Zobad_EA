//+------------------------------------------------------------------+
//|                                 ReversePyramid_Martingale-V2.mq4 |
//|                                   Copyright 2017, QuantSoftware. |
//|                                    https://www.quantsoftware.net |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, QuantSoftware."
#property link      "https://www.quantsoftware.net"
#property version   "2.00"
#property strict


#include "EntrySignal.mqh"
#include "MoneyManagement.mqh"
#include "Indicators.mqh"


EntrySignal     *algo ;
MoneyManagement *mm   ;
Indicators      *ind  ;

enum Strat_typeII
            {
               _PAIR_REVERSAL = 10,   //Pair Reversal
               _PAIR_DIRECTIONAL = 9, //PairM Directional
               _PAIR_MREVErsAL = 11, //PairM Reversal
               _DIRECTIONAL = 4,  //Directional
               _REVERSAL    = 5,  //Reversal
               //BOTH        = 1,  //Dir&Rev
               //ST_DEV_C2   = 2,  //Standard Deviation 2
               //ST_DEV_C3   = 3,  //Standard Deviation 3
               _BREAKIN     = 6,  //Break in
               _DIRECTIONAL_Range = 7,  //Directional Volatility
               _REVERSAL_Range    = 8,  //Reversal Volatility       
            };

enum LotType
{
   MANUAL = 0,
   AUTO    = 1,
};
enum Take_Profit_Type{
   
   FIXED = 0,
   VOLATILITY = 1,
   MID_BB = 2,
   OPP_BAND = 3
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
int                     _count=0;
int                    _ticket;
double                 _tp;
double                 _sl;
int                    _opType;
extern int              Magic_Number       = 1         ;             //Magic Number 
extern bool             useLegacy          = false     ;             //Use Legacy Entry Signal
string          set="----------Consecutive Losses--------------";//Consecutive Losses Settings
bool                    useConsecutive     = false     ;             //Use Consecutive Loss
int                     noConsqLossAllowed = 3         ;             //Consecutive Losses Allowed
double                  percentReduction   = 5         ;             //Lot Size Percent Reduction
extern string          setLot=     "-------Lot Setting -------"       ;
extern LotType          lotType            = MANUAL      ;             //Lot Type
extern double           _risk              = 0.02       ;             //%Available Balance::Lot
extern double           LotSize            = 0.01      ;             //Position:: Lot SizeY(Manual)
extern double           LotSizeX            = 0.01      ;             //Position:: Lot Size PairX(Manual)
extern string          order1=     "-------Order -------"             ;             //Order 1 Settings
bool                   order1Open         =  false    ; 
extern Strat_typeII      _strat_type        = _PAIR_REVERSAL ;           //Strategy:: Type      
extern bool             useStrategy1       = true      ;             //Strategy:: Use Strategy
bool                    useHedge           = false     ;             //Strategy:: Use Hegde 
extern string           pairY              = "US30"    ;             //Pair1
extern string           pairX              = "US500"   ;             //Pair2
 string          reversalSet="-------Reversal Strategy -------" ;             //Reversal TP and SL Settings
bool             visible            = false      ;
extern Take_Profit_Type TP_Type            = MID_BB;             //TP:: Type
extern Take_Profit_Type SL_Type            = MID_BB;             //SL:: Type
extern double           TP_Value           =  3.0      ;             //TP:: Volatility/Fixed(Points)
extern double           SL_Value           =  3.0      ;             //SL:: Volatility/Fixed(Points)
extern double           _range             = 2.5       ;             
extern int              leg                = 6         ;
extern double           multiply           = 2.5       ;
extern bool             EQ_Based           = true      ;             //Use Equity Based TP
extern bool             useGridStop        = false     ;             //Us Equity Based SL
extern double           _profitTarget      = 1000      ;             //Profit Target
extern double           _stopLevel         = -500.0    ;             //Stop Out Level
int              _timegap1          = 31        ;             //Order 1 time gap(in mins)
double                 _highestStop1                  ;
double                 _lowestStop1                   ;
bool                   LR_Flag            = false     ;      
double                 prev_lot           =0.0        ;
int                    _cur_total         = 0         ;
bool                   startFlag          = false     ;
datetime expiry = D'2018.06.06 00:00';
bool bExpiryAlertDelieverd = false;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   expiry = D'2018.06.06 00:00';
   bExpiryAlertDelieverd = false;
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
   if((TimeCurrent()>expiry)){
      if(bExpiryAlertDelieverd ==false){
         Alert("The EA has Expired...");bExpiryAlertDelieverd=true;
         }
   }
   else{
       if(startFlag == true){
         Print("Start is false now");
         _cur_total = isOrdersTotal(Magic_Number);
         Print("Closed. _Cur_total[",_cur_total,"], isTotal[",isOrdersTotal(Magic_Number),"]");
         startFlag = false;
        }
        
        mm.EquityBasedClose(EQ_Based,_profitTarget,useGridStop,_stopLevel,Magic_Number);
        //Print("Count[",_count,"]");
        if(isOrdersTotal(Magic_Number)<1 ){         
         if( IsNewBar()/* && (_count ==0 || _count==leg)*/){
            int ccode = IsSignal(_strat_type,_range);
           /* if(_strat_type == _PAIR_DIRECTIONAL && ccode != FAIL){
               if(ccode == DIRECTIONAL_BUY) mm.PlaceOrderPairs(pairY,pairX,OP_BUY,OP_SELL,LotSize,LotSize,Magic_Number,"Pair Directional",TP_Type,TP_Value,SL_Type,SL_Value );
               else if(ccode == DIRECTIONAL_SELL) mm.PlaceOrderPairs(pairY,pairX,OP_SELL,OP_BUY,LotSize,LotSize,Magic_Number,"Pair Directional",TP_Type,TP_Value,SL_Type,SL_Value );
               if(isOrdersTotal(Magic_Number)==2)_count = 1;
               Print("New Order");*/
            if(_strat_type == _PAIR_DIRECTIONAL && ccode != FAIL){
               if(ccode == DIRECTIONAL_BUY)
                  PlaceOrderPair( OP_BUY,OP_SELL,"Pair Directional");
               else if(ccode == DIRECTIONAL_SELL) 
                  PlaceOrderPair(OP_SELL,OP_BUY,"Pair Directional");
               if(isOrdersTotal(Magic_Number)==2)_count = 1;
               Print("New Order");   
            }
            else if(_strat_type == _PAIR_REVERSAL && ccode != FAIL){
               if(ccode == REVERSAL_BUY)
                  PlaceOrderPair( OP_BUY,OP_SELL,"Pair Reversal");
               else if(ccode == REVERSAL_SELL) 
                  PlaceOrderPair(OP_SELL,OP_BUY,"Pair Reversal");
               if(isOrdersTotal(Magic_Number)==2)_count = 1;
               Print("New Order");   
            }
            //if(ccode== DIRECTIONAL_BUY || ccode == REVERSAL_BUY)PlaceOrder(_strat_type,OP_BUY); 
            //else if(ccode== DIRECTIONAL_SELL || ccode == REVERSAL_SELL)PlaceOrder(_strat_type,OP_SELL);           
         }   
      }
      /*if(isOrdersTotal(Magic_Number)>0 || _count >1 )*/else{CloseOrderPair(pairY,pairX);CutAndReverse(pairY,pairX);CutAndReverse(pairY,pairX);/*Print("Count[",_count,"]");Print("isOrdersTotal[",isOrdersTotal(Magic_Number),"]");*/}
      
     }
     Comment("_Count[",(string)_count,"] total Orders[",isOrdersTotal(Magic_Number),"],TP[",_tp,"], SL[",_sl,"]"); 
  }
//+------------------------------------------------------------------+
void CloseOrder(){
   int ticket=0,op = 0;
   double lot=0.0,openprice=0.0;
   for(int i =0; i<OrdersTotal(); i++){
      if(OrderSelect(i,SELECT_BY_POS,MODE_OPEN)>0){
         if(OrderMagicNumber()==Magic_Number && OrderSymbol()==Symbol()){
            ticket = OrderTicket();
            lot = OrderLots();
            openprice = OrderOpenPrice();
            op =OrderType();      
         }
      }
   }
   int errCode = StopHit(op,_tp,_sl);
   RefreshRates();
   if( (op==OP_BUY && errCode == 1) ){Print("Take Profit");if(OrderClose(ticket,lot,Bid,3,clrDarkMagenta)==true)_tp=0.0;_sl=0.0;}
   if(  op==OP_BUY && errCode == -1 ){Print("Stop Loss");if(OrderClose(ticket,lot,Bid,3,clrDarkMagenta)==true)_tp=0.0;_sl=0.0;}
   else if(op==OP_SELL && errCode == 1){Print("Take Profit");if(OrderClose(ticket,lot,Ask,3,clrDarkMagenta)==true)_tp=0.0;_sl=0.0;}
   else if(op==OP_SELL && errCode == -1){Print("Stop Loss");if(OrderClose(ticket,lot,Ask,3,clrDarkMagenta)==true)_tp=0.0;_sl=0.0;}
}
void CloseOrderPair(string y, string x){
   int ticket=0,op = 0;
   double lot=0.0,openprice=0.0;
   for(int i =0; i<OrdersTotal(); i++){
      if(OrderSelect(i,SELECT_BY_POS,MODE_OPEN)>0){
         if(OrderMagicNumber()==Magic_Number && (OrderSymbol()==y)){//selecting only pair y because its also use for opening
            ticket = OrderTicket();
            lot = OrderLots();
            openprice = OrderOpenPrice();
            op =OrderType();
            int errCode = StopHitPair(op);
            double bid = MarketInfo(OrderSymbol(),MODE_BID);
            double ask = MarketInfo(OrderSymbol(),MODE_ASK);
            if( (op==OP_BUY && errCode == 1) ){Print("Take Profit");if(OrderClose(ticket,lot,bid,3,clrDarkMagenta)==true)_tp=0.0;_sl=0.0;/*_count = 0;*/}
            if(  op==OP_BUY && errCode == -1 ){Print("Stop Loss");if(OrderClose(ticket,lot,bid,3,clrDarkMagenta)==true)_tp=0.0;_sl=0.0;}
            else if(op==OP_SELL && errCode == 1){Print("Take Profit");if(OrderClose(ticket,lot,ask,3,clrDarkMagenta)==true)_tp=0.0;_sl=0.0;}
            else if(op==OP_SELL && errCode == -1){Print("Stop Loss");if(OrderClose(ticket,lot,ask,3,clrDarkMagenta)==true)_tp=0.0;_sl=0.0;}      
         }
      }
   }
}
int StopHit(int op, double tp, double sl)
{
   //0=fail, 1=tp,-1=sl
   RefreshRates();
   if(!visible){
      if(op==OP_BUY){
          if(Bid> tp){/*Print("ask[",Ask,"]bid[",Bid,"]");*/return(1);}
          else if(Bid<sl){/*Print("ask[",Ask,"]bid[",Bid,"]");*/return(-1);}       
      }
      else if(op==OP_SELL){
         if(Ask<tp){/*Print("ask[",Ask,"]bid[",Bid,"]");*/return(1);}
         else if(Ask>sl){/*Print("ask[",Ask,"]bid[",Bid,"]");*/ return(-1);}
      }
   }
   return(0);
}
int StopHitPair(int op)
{
   int period = 14;
   //0=fail, 1=tp,-1=sl
   if(!visible){
         //Check PRAtr value if>=_tp return 1
         double pr_atr = ind.iPR(pairY,pairX,period,0,0);
         if(op == OP_BUY)
         {
             if(pr_atr >= _tp){ Print("TP");return 1;}
         //else if PRATR<= _sl return -1
            else if(pr_atr <= _sl){Print("SL"); return -1;}
         }   
         else if(op == OP_SELL)
         {
             if(pr_atr <= _tp){ Print("TP"); return 1;}
         //else if PRATR<= _sl return -1
            else if(pr_atr >= _sl){Print("SL"); return -1;}
         }      
         //else return 0
         else return 0;     
      
   }
   return(0);
}   
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
bool PlaceOrderPair(int op_y, int op_x,string comment)
{
  // double _tp =0.0, _sl = 0.0;
   int ATR_period = 14;
   mm.PlaceOrderPairsHidden(pairY,pairX,op_y,op_x,LotSize,LotSizeX,Magic_Number,comment);
   if(_strat_type == _PAIR_REVERSAL)
   {
      _tp = mm.CalculatePairTP(pairY,pairX,ATR_period,op_y,TP_Type,TP_Value);
      _sl = mm.CalculatePairSL(pairY,pairX,ATR_period,op_y,SL_Type,SL_Value);
      _count++;
   }
   else if(_strat_type == _PAIR_DIRECTIONAL)
   {
      if(!TP_Type == MID_BB)
      {
         _tp = mm.CalculatePairTP(pairY,pairX,ATR_period,op_y,TP_Type,TP_Value);
         _sl = mm.CalculatePairSL(pairY,pairX,ATR_period,op_y,SL_Type,SL_Value);
      }
      else
      {
         _sl = mm.CalculatePairTP(pairY,pairX,ATR_period,op_y,TP_Type,TP_Value);
         _tp = mm.CalculatePairSL(pairY,pairX,ATR_period,op_y,SL_Type,SL_Value);
      }
      _count++;   
   }   
   
   return false;
   //return ();
}
bool PlaceOrder(int strat, int op){
   double openprice=0.0, lot=0.0,tp=0.0,sl=0.0;
   string comment;
   lot = mm.CalculatePositionSize(lotType,LotSize,_risk);
   if(op == OP_BUY){
      if(strat == DIRECTIONAL)comment ="Directional Buy";
      else if(strat == REVERSAL)comment ="Reversal Buy";
      else if(strat == _PAIR_DIRECTIONAL) comment = "Pair Directional";    
    openprice = Bid;
   }
   else if(op==OP_SELL){
    //comment ="Sell";
    if(strat == DIRECTIONAL)comment ="Directional Sell";
    else if(strat == REVERSAL)comment ="Reversal Sell";
    else if(strat == _PAIR_DIRECTIONAL) comment = "Pair Directional";
    openprice = Ask;    
   }
   mm.PlaceOrderHidden(op,lot,Magic_Number,(int)comment);
    _tp = mm.CalculateTP(op,TP_Type,TP_Value);
    _sl = mm.CalculateSL(op,openprice, SL_Type,SL_Value);
    _opType = op;
   _count++;
   return false;
}
bool PlaceOrder(int op, double lot){
   double openprice=0.0, tp=0.0,sl=0.0;
   string comment;
   //lot = mm.CalculatePositionSize(lotType,LotSize,_risk);
   if(op == OP_BUY){
    comment ="Buy";    
    openprice = Bid;
   }
   else if(op==OP_SELL){
    comment ="Sell";
    openprice = Ask;    
   }
   mm.PlaceOrderHidden(op,lot,Magic_Number,(int)comment);
    _tp = mm.CalculateTP(op,TP_Type,TP_Value);
    _sl = mm.CalculateSL(op,openprice, SL_Type,SL_Value);
    _opType = op;
   _count++;

   return false;
}
void SendOrder(string symbol,int type,double lot,double price_s,int slippage_v,double stop_loss_v,double take_profit_v,string comment,int magic_v,color color_v){
  int countTentative=3;
  int tentative=0;
  int ticket=0;             
  while(IsConnected() && ticket < 1 && tentative <= countTentative){
    RefreshRates();
    ticket = OrderSend(symbol,type,lot,price_s,slippage_v,stop_loss_v,take_profit_v,comment,magic_v,0,color_v);
    Sleep(1000);            
    tentative++;
                  
  }
  _ticket = ticket;

}
int CutAndReverse(){
      int value=isOrdersTotal(Magic_Number);      
      if(value==0){
      for(int i=OrdersHistoryTotal()-1; i>=0; i--)       //Cycle for all orders..
         {                                        //displayed in the terminal
            if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY))//If there is the next one
              { 
               if(OrderMagicNumber() == Magic_Number && OrderSymbol()==Symbol())
               {   
                  if(OrderType()==OP_BUY){
                     Print("leg[",_count,"]");
                     if(OrderOpenPrice()>OrderClosePrice()&& _count<leg ){
                        //SendOrder(Symbol(),OP_SELL,OrderLots()*multiply,Bid,3,0,0," Cut&Reverse: Sell ",Magic_Number,Red);
                        PlaceOrder(OP_SELL,OrderLots()*multiply);
                        break;
                     }else {
                           _count =0;
                           return FAIL;
                        //SendOrder(Symbol(),OP_BUY,lotes,Ask,3,0,0," martingale buy ",magic,Blue);
                     }
                  }
                  if(OrderType()==OP_SELL){
                     Print("leg[",_count,"]");
                     if(OrderOpenPrice()<OrderClosePrice()&& _count<leg){
                        //SendOrder(Symbol(),OP_BUY,OrderLots()*multiply,Ask,3,0,0," Cut&Reverse: Buy ",Magic_Number,Blue);
                        PlaceOrder(OP_BUY,OrderLots()*multiply);
                        break;
                     }else{
                        _count = 0;
                        return FAIL;
                       // SendOrder(Symbol(),OP_BUY,lotes,Ask,3,0,0," martingale buy ",magic,Blue);
                     }
                  }                                   
               }
             }
         }
         
    }                
   return(0);
}
int CutAndReverse(string y, string x){
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
               _tp = NormalizeDouble( mm.CalculatePairTP(y,x,14,op_x,TP_Type,TP_Value),MarketInfo(y,MODE_DIGITS));
               _sl = NormalizeDouble( mm.CalculatePairSL(y,x,14,op_x,SL_Type,SL_Value),MarketInfo(y,MODE_DIGITS));
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
      else if(strat == _PAIR_DIRECTIONAL){
         int ccode = algo.PR_Directional(pairY,pairX);
         if(ccode == DIRECTIONAL_BUY  || ccode == DIRECTIONAL_SELL ){Print("Pair Breakin"); return ccode;}
      
      }
      else if(strat == _PAIR_REVERSAL){
         int ccode = algo.PR_Reversal(pairY,pairX);
         if(ccode == REVERSAL_BUY  || ccode == REVERSAL_SELL ){Print("Pair Breakout"); return ccode;}
      }
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