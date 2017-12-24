//+------------------------------------------------------------------+
//|                                            testCutandReverse.mq4 |
//|                                                    Zobad Mahmood |
//|                                   zobad.mahmod@quantsoftware.net |
//+------------------------------------------------------------------+
#property copyright "Zobad Mahmood"
#property link      "zobad.mahmod@quantsoftware.net"
#property version   "1.00"
#property strict
#include "EntrySignal.mqh"
#include "MoneyManagement.mqh"
#include "Indicators.mqh"


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
int                     _count=0;
int                    _ticket;
double                 _tp;
double                 _sl;
int                    _opType;
extern int              Magic_Number       = 1         ;             //Magic Number 
extern bool             useLegacy          = false     ;             //Use Legacy Entry Signal
string          set="----------Consecutive Losses--------------";//Consecutive Losses Settings
bool             useConsecutive     = false     ;             //Use Consecutive Loss
int              noConsqLossAllowed = 3         ;             //Consecutive Losses Allowed
double           percentReduction   = 5         ;             //Lot Size Percent Reduction
extern string          setLot=     "-------Lot Setting -------"       ;
extern LotType          lotType            = AUTO      ;             //Lot Type
extern double           _risk              = 2.0       ;             //%Available Balance::Lot
extern double           LotSize            = 0.5       ;             //Position:: Lot Size(Manual)
extern string          order1=     "-------Order -------"             ;             //Order 1 Settings
bool                   order1Open         =  false    ; 
extern Strat_type      _strat_type        = DIRECTIONAL ;           //Strategy:: Type      
extern bool             useStrategy1       = true      ;             //Strategy:: Use Strategy
extern bool             useHedge           = false     ;             //Strategy:: Use Hegde 
extern string          reversalSet="-------Reversal Strategy -------" ;             //Reversal TP and SL Settings

extern Take_Profit_Type TP_Type            = VOLATILITY;             //Reversal TP:: Type
extern Take_Profit_Type SL_Type            = VOLATILITY;             //Reversal SL:: Type
extern double           TP_Value           =  4.5      ;             //Reversal TP:: Volatility/Fixed(Points)
extern double           SL_Value           =  1.5      ;             //Reversal SL:: Volatility/Fixed(Points)
/*extern bool             useTrail           = false     ;             //Trail:: Use Trail
extern _type            _trail_type1       = FIX       ;             //Trail:: Type 
extern double           _trailBy           = 40        ;             //Trail Volat/Fixed:: Trail by
extern bool             _breakEven1        = false     ;             //Breakeven:: Use jump to Breakeven
extern int              _whenJump1         = 25        ;             //Breakeven:: When to Jump
extern int              _jumpBy1           = 6         ;             //Breakeven:: Points to add after Jump
*/extern int              leg                = 6         ;
extern double           multiply           = 2.5       ;
extern bool             EQ_Based           = true      ;             //Use Equity Based TP
extern bool             useGridStop        = false     ;             //Us Equity Based SL
extern double           _profitTarget      = 1000      ;             //Profit Target
extern double           _stopLevel         = -500.0    ;             //Stop Out Level
int              _timegap1          = 31        ;             //Order 1 time gap(in mins)
//extern bool             _use_risk_candle1  = false     ;             //Risk Management:: Use Risk Management
//extern int              _risk_candle1      = 4         ;             //Risk Management:: Number of Candles to read
double                 _highestStop1                  ;
double                 _lowestStop1                   ;
//extern bool             _gapCloseCheck1    = false     ;             //Close Candle:: Use time gap
//extern int              _whenClose1        = 50        ;             //Close Candel:: Time gap in minutes
bool                   LR_Flag            = false     ;      
double                 prev_lot           =0.0        ;
int                    _cur_total         = 0         ;
bool                   startFlag          = false     ;

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
   }
   mm.EquityBasedClose(EQ_Based,_profitTarget,useGridStop,_stopLevel,Magic_Number);
   if(isOrdersTotal(Magic_Number)<1 && _count == 0){
      if( IsNewBar()){ PlaceOrder(_strat_type,OP_BUY); }   
   }
   else{/*int errCode=StopHit(OP_BUY,_tp,_sl);*/CloseOrder();CutAndReverse();}
   
  }
//+------------------------------------------------------------------+
void CloseOrder(){
   //if(errCode == 0)return;
   int total = isOrdersTotal(Magic_Number);
   int ticket=0,op = 0;
   double lot=0.0,openprice=0.0;
   for(int i =0; i<total; i++){
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
   if( (op==OP_BUY && errCode == 1) ){if(OrderClose(ticket,lot,Bid,3,clrDarkMagenta)==true)_tp=0.0;_sl=0.0;}
   if(  op==OP_BUY && errCode == -1 ){if(OrderClose(ticket,lot,Bid,3,clrDarkMagenta)==true)_tp=0.0;_sl=0.0;}
   else if(op==OP_SELL && errCode == 1){if(OrderClose(ticket,lot,Ask,3,clrDarkMagenta)==true)_tp=0.0;_sl=0.0;}
   else if(op==OP_SELL && errCode == -1){if(OrderClose(ticket,lot,Ask,3,clrDarkMagenta)==true)_tp=0.0;_sl=0.0;}
}
int StopHit(int op, double tp, double sl)
{
   //0=fail, 1=tp,-1=sl
   RefreshRates();
   if(op==OP_BUY){
       if(Bid> tp){Print("ask[",Ask,"]bid[",Bid,"]");return(1);}
       else if(Bid<sl){Print("ask[",Ask,"]bid[",Bid,"]");return(-1);}       
   }
   else if(op==OP_SELL){
      if(Ask<tp){Print("ask[",Ask,"]bid[",Bid,"]");return(1);}
      else if(Ask>sl){Print("ask[",Ask,"]bid[",Bid,"]"); return(-1);}
   }
   return(0);
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

bool PlaceOrder(int strat, int op){
   double openprice=0.0, lot=0.0,tp=0.0,sl=0.0;
   string comment;
   lot = mm.CalculatePositionSize(lotType,LotSize,_risk);
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

      
      
      
      
      
        