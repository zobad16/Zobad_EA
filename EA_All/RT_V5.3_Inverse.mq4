//+------------------------------------------------------------------+
//|                                              RT_V5.3_Inverse.mq4 |
//|                                                    Zobad Mahmood |
//|                                          zobad.mahmood@gmail.com |
//| Progress:
//| - Correct placement of tp and sl
//| - Revised Trailing stop.
//| - trails by 25% of the trail point
//| -Fixed points are placed correctly for tp and sl 
//+------------------------------------------------------------------+
#property copyright "Zobad Mahmood"
#property link      "zobad.mahmood@gmail.com"
#property version   "1.00"
#property strict


#define FAIL  0
#define BUY   1
#define SELL  2
#define _TRUE  3
#define _FALSE 4
enum Take_Profit_Type{
   
   FIXED=0,
   VOLATILITY=1,
   MID_BB=2
};
enum Strategy_Type
{
   BREAKOUT=0,
   BREAKIN=1,   
   BANDTOUCH=2,   
};
bool                   flag_b=false;
bool                   flag_s=false;
bool                   buyIgnore1=false;
bool                   sellIgnore1=false;
bool                   buyIgnore1v2=false;
bool                   sellIgnore1v2=false;
bool                   buyIgnore2=false;
bool                   sellIgnore2=false;
bool                   buyIgnore3=false;
bool                   sellIgnore3=false;
bool                   buyIgnore4=false;
bool                   sellIgnore4=false;
input int              Magic_Number = 1;                 //Magic Number
extern string          order1="-------Order_1--------";  //Order 1 Settings
bool                   order1Open=false;
extern string          Strat_Name="Break Out Inverse";           //Strategy Name
input bool             useStrategy1=true;                //Use Strategy
input double           LotSize=1.0;                      //Lot Size
input Take_Profit_Type TP_Type= VOLATILITY;              //Take Profit Type
input Take_Profit_Type SL_Type= VOLATILITY;              //Stop Loss Type
input double           TP_Volatility_Factor=2.0;         //Take Profit Volatility Factor
input double           SL_Volatility_Factor=1.0;         //Stop Loss Volatility Factor
input double           TP_Fixed=25.0;                    //Take Profit Fixed(Points)
input double           SL_Fixed=12.0;                    //Stop Loss Fixed(Points)
input int              _timegap1=31;                     //Order 1 time gap(in mins)
input bool             _trail1 = false;                  //Use Trailing Stop For Order 1
input int              _trailPoint1;                     //When to Trail
input bool             _breakEven1 = false;              //Use jump to breakeven
input int              _whenJump1=25;                    //When to Jump to Breakeven
input int              _jumpBy1=6;                       //Points to add after the Breakeven Jump
input bool             _use_risk_candle1=false;           //Use Risk Management
input int              _risk_candle1=4;                  //candles to Read for Risk Management
double                 _highestStop1;
double                 _lowestStop1;
input bool             _gapCloseCheck1=false;             //Use Close Candle after a certain time gap
input int              _whenClose1= 50;                  //Time gap in minutes 

extern string          order1v2="-------Order_1V2--------";  //Order 1 Settings
bool                   order1v2Open=false;
extern string          Strat_Name1v2="Break Out2 Inverse";         //Strategy Name
input bool             useStrategy1v2=false;                //Use Strategy
input double           LotSize1v2=1.0;                     //Lot Size
input Take_Profit_Type TP_Type1v2= VOLATILITY;             //Take Profit Type
input Take_Profit_Type SL_Type1v2= VOLATILITY;             //Stop Loss Type
input double           TP_Volatility_Factor1v2=2.0;        //Take Profit Volatility Factor
input double           SL_Volatility_Factor1v2=1.0;        //Stop Loss Volatility Factor
input double           TP_Fixed1v2=25.0;                   //Take Profit Fixed(Points)
input double           SL_Fixed1v2=12.0;                   //Stop Loss Fixed(Points)
input int              _timegap1v2=31;                     //Order 1 time gap(in mins)
input bool             _trail1v2 = false;                  //Use Trailing Stop For Order 1v2
input int              _trailPoint1v2;                     //When to Trail
input bool             _breakEven1v2 = false;              //Use jump to breakeven
input int              _whenJump1v2=25;                    //When to Jump to Breakeven
input int              _jumpBy1v2=6;                       //Points to add after the Breakeven Jump
input bool             _use_risk_candle1v2=true;           //Use Risk Management
input int              _risk_candle1v2=4;                  //candles to Read for Risk Management
double                 _highestStop1v2;
double                 _lowestStop1v2;
input bool             _gapCloseCheck1v2=true;             //Use Close Candle after a certain time gap
input int              _whenClose1v2= 50;                  //Time gap in minutes 

extern string          order2="-------Order_2--------";    //Order 2 Settings   
bool                   order2Open= false;
extern string          Strat_Name2="Break In Inverse";             //Strategy Name
input bool             useStrategy2=false;                  //Use Strategy
input double           LotSize2=1.0;                       //Lot Size
input Take_Profit_Type TP_Type2= VOLATILITY;               //Take Profit Type
input Take_Profit_Type SL_Type2= VOLATILITY;               //Stop Loss Type
input double           TP_Volatility_Factor2=3.0;          //Take Profit Volatility Factor
input double           SL_Volatility_Factor2=1.5;          //Stop Loss Volatility Factor
input double           TP_Fixed2=25.0;                     //Take Profit Fixed(Points)
input double           SL_Fixed2=12.0;                     //Stop Loss Fixed(Points)
input int              _timegap2=10;                       //Order 2 time gap(in mins)
input bool             _trail2 = false;                    //Use Trailing Stop For Order 2
input int              _trailPoint2;                       //When to Trail  
input bool             _breakEven2 = false;                //Use jump to breakeven
input int              _whenJump2=25;                      //When to Jump to Breakeven
input int              _jumpBy2=6;                         //Points to add after the Breakeven Jump
input bool             _use_risk_candle2=true;             //Use Risk Management
input int              _risk_candle2=4;                    //candles to Read for Risk Management
double                 _highestStop2;
double                 _lowestStop2;
input bool             _gapCloseCheck2=true;               //Use Close Candle after a certain time gap
input int              _whenClose2= 50;                    //Time gap in minutes 

extern string          order3="-------Order_3--------";    //Order 3 Settings
bool                   order3Open=false;   
extern string          Strat_Name3="Band Touch Inverse";           //Strategy Name
input bool             useStrategy3=false;                  //Use Strategy
input double           LotSize3=1.0;                       //Lot Size
input Take_Profit_Type TP_Type3= VOLATILITY;               //Take Profit Type
input Take_Profit_Type SL_Type3= VOLATILITY;               //Stop Loss Type
input double           TP_Volatility_Factor3=3.0;          //Take Profit Volatility Factor
input double           SL_Volatility_Factor3=1.5;          //Stop Loss Volatility Factor
input double           TP_Fixed3=25.0;                     //Take Profit Fixed(Points)
input double           SL_Fixed3=12.0;                     //Stop Loss Fixed(Points)
input int              _timegap3=10;                       //Order 3 time gap(in mins)
input bool             _trail3 = false;                    //Use Trailing Stop For Order 3
input int              _trailPoint3;                       //When to Trail  
input bool             _breakEven3 = false;                //Use jump to breakeven
input int              _whenJump3=25;                      //When to Jump to Breakeven
input int              _jumpBy3=6;                         //Points to add after the Breakeven Jump
input bool             _use_risk_candle3=true;             //Use Risk Management
input int              _risk_candle3=4;                    //candles to Read for Risk Management
double                 _highestStop3;
double                 _lowestStop3;
input bool             _gapCloseCheck3=true;               //Use Close Candle after a certain time gap
input int              _whenClose3= 50;                    //Time gap in minutes 

extern string          order4="-------Order_4--------";   //Order 4 Settings
bool                   order4Open=false;   
extern string          Strat_Name4="Reversal";          //Strategy Name
input bool             useStrategy4=false;               //Use Strategy
input double           LotSize4=1.0;                    //Lot Size
input Take_Profit_Type TP_Type4= VOLATILITY;            //Take Profit Type
input Take_Profit_Type SL_Type4= VOLATILITY;            //Stop Loss Type
input double           TP_Volatility_Factor4=3.0;       //Take Profit Volatility Factor
input double           SL_Volatility_Factor4=1.5;       //Stop Loss Volatility Factor
input double           TP_Fixed4=25.0;                  //Take Profit Fixed(Points)
input double           SL_Fixed4=12.0;                  //Stop Loss Fixed(Points)
input int              _timegap4=10;                    //Order 4 time gap(in mins)
input bool             _trail4 = false;                 //Use Trailing Stop For Order 4
input int              _trailPoint4;                    //When to Trail  
input bool             _breakEven4 = false;             //Use jump to breakeven
input int              _whenJump4=25;                   //When to Jump to Breakeven
input int              _jumpBy4=6;                      //Points to add after the Breakeven Jump
input int              _candle_Check=4 ;                //Candles to read
input bool             _use_risk_candle4=true;            //Use Risk Management
input int              _risk_candle4=4;                  //candles to Read for Risk Management
double                 _highestStop4;
double                 _lowestStop4;
input bool             _gapCloseCheck4=true;              //Use Close Candle after a certain time gap
input int              _whenClose4= 50;                   //Time gap in minutes 

extern string          order5="------Order_5----------";  //Order 5 Settings
bool                   order5Open=false;
extern string          Strat_Name5="Grid";                //Strategy Name
input bool             useStrategy5= false;               //Use Strategy
input int              numberOfLegs=5;                    //Number of Legs
input double           startLot=0.5;                      //Starting lots
input int              legIncreaseDecrease=0;             //Increase or decrease lot size on each leg. 1 = increase 0=decrease 
input int              increaseLLotBy  = 2;               //Lot Size ratio to increase each leg by(in multiples)
input int              decreaseLLotBy  = 2;               //Lot Size ratio to decrease each leg by(in multiples)

extern string          bb_Set="--Bollinger Band Settings--"; //Bollinger Band Settings
input ENUM_TIMEFRAMES  BB_Chart_Timeframe= PERIOD_CURRENT;  //Bollinger Band Chart Time 
input int              BB_Period=14;                    //Bollinger Band Period

extern string          atr_Set="--ATR Settings--";      //Order 3 Settings
input int              ATR_Period=14;                   //ATR Period 
input ENUM_TIMEFRAMES  ATR_Charts_Period = PERIOD_CURRENT;  //ATR Chart Time
input int              Slippage=33;                     //Slippage
extern string          risk_Set="--Risk Management Settings--";// Risk Management settings 
input bool             use_RiskManagement=false;        //Use Risk Management
input double           Risk_Management;                 //Risk Management % from equity 
int count_b, count_s;
double _point;
double Mid_Price=0.0;

double MyPoint()
  {
   double CalcPoint = 0;
   
   if(_Digits == 2 || _Digits == 3) CalcPoint = 0.01;
   else if(_Digits == 4 || _Digits == 5) CalcPoint = 0.0001;
   
   return(CalcPoint);
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

int TotalOpenOrder()
{
  int total_order=0;
  for(int order=0; order<OrdersTotal();order++){
     if(OrderSelect(order,SELECT_BY_POS,MODE_TRADES)==false)break;
     if(OrderMagicNumber()==Magic_Number && OrderSymbol()==_Symbol)
     {
        total_order++;
     }
  }  
  return(total_order);
}
//+------------------------------------------------------------------+
//|   Entry Rule Check                                               |
//+------------------------------------------------------------------+

//Check for Breakout Pattern 
int Pattern1()
{
   if(order1Open)return FAIL;
   else if(Sell_Alert_1())return SELL;
   else if(Buy_Alert_1())return BUY;
   return FAIL;
}
//Check for Breakin Pattern 
int Pattern1v2()
{
   if(order1v2Open)return FAIL;
   else if(Sell_Alert_1v2())return SELL;
   else if(Buy_Alert_1v2())return BUY;
   return FAIL;
}

//Check for Breakin Pattern 
int Pattern2()
{
   if(order2Open)return FAIL;
   else if(Sell_Alert_2())return SELL;
   else if(Buy_Alert_2())return BUY;
   return FAIL;
}

//Check for Touch Pattern 
int Pattern3()
{   
   if(order3Open) return FAIL;
   else if(Sell_Alert_3()) return SELL;
   else if(Buy_Alert_3())  return BUY;
   return FAIL;
}

//Check for Reversal Strategy
void Pattern4(bool & b, int &bu,bool &s, int &se, double & h, double & l, int risk)
{
    if(bu>=_candle_Check)
     {
      Print("Buy Flag. Sell Order(Reversal)");
      bu=0;
      b=false;
      Place_Sell_Order4();
      SetHighest(_highestStop4, risk , _use_risk_candle4);
      order4Open=true;
      
     }
    else if(se>=_candle_Check)
     {
      Print("Sell Flag. Buy Order(Reversal)");
      se=0;
      s=false;
      Place_Buy_Order4();
      SetLowest(_lowestStop4, risk, _use_risk_candle4);
      order4Open=true;
     }

}
//Check for Grid Pattern
int Pattern5()
{
   if(Sell_Alert_5()) return SELL;
   else if(Buy_Alert_5()) return BUY;
   return FAIL;
}
//Breakout Pattern
bool Sell_Alert_1()
{
   double bb_high=iBands(NULL,0,BB_Period,2,0,PRICE_CLOSE,MODE_UPPER,1);
   double bb_high2=iBands(NULL,0,BB_Period,2,0,PRICE_CLOSE,MODE_UPPER,2); 
   if(Open[1]<bb_high && Close[1]>bb_high ) return true;
   return false;
}  

bool Buy_Alert_1()
{
   double bb_low=iBands(NULL,0,BB_Period,2,0,PRICE_CLOSE,MODE_LOWER,1);
   if(Open[1]>bb_low && Close[1]< bb_low)  return true;   
   return false;
}  
bool Sell_Alert_1v2()
{
   double bb_high=iBands(NULL,0,BB_Period,2,0,PRICE_CLOSE,MODE_UPPER,1);
   double bb_high2=iBands(NULL,0,BB_Period,2,0,PRICE_CLOSE,MODE_UPPER,2); 
   if(Open[1]>bb_high2 && Close[1]<bb_high2 )
   { 
     Print("Sell Alert"); 
     return true;
   }             
   return false;
}  

bool Buy_Alert_1v2()
{
   double bb_low=iBands(NULL,0,BB_Period,2,0,PRICE_CLOSE,MODE_LOWER,1);
   double bb_low2=iBands(NULL,0,BB_Period,2,0,PRICE_CLOSE,MODE_LOWER,2);
   if(Open[1]<bb_low2 && Close[1]>bb_low2)
   {  
     Print("Buy Order Alert");
     return true;
   }
   return false;
} 
//Breakin Pattern
bool Sell_Alert_2()
{
   double bb_high=iBands(NULL,0,BB_Period,2,0,PRICE_CLOSE,MODE_UPPER,1);
   double bb_high2=iBands(NULL,0,BB_Period,2,0,PRICE_CLOSE,MODE_UPPER,2); 
   if(Open[2]>bb_high2 && Close[2]<bb_high2 )
   { 
     if(Close[1]> Close[2] && Close[1]<bb_high){Print("Sell Alert"); return true;}
   }             
   return false;
}  

bool Buy_Alert_2()
{
   double bb_low=iBands(NULL,0,BB_Period,2,0,PRICE_CLOSE,MODE_LOWER,1);
   double bb_low2=iBands(NULL,0,BB_Period,2,0,PRICE_CLOSE,MODE_LOWER,2);
   if(Open[2]<bb_low2 && Close[2]>bb_low2)
   {  
      if(Close[1]< Close[2] && Close[1]>bb_low){ Print("Buy Order Alert"); return true;}
   }
   return false;
} 
//
bool Sell_Alert_3()
{
   double bb_high=iBands(NULL,0,BB_Period,2,0,PRICE_CLOSE,MODE_UPPER,0);
   //Print("bb_high[",bb_high,"] high[",High[0],"]");
   if(High[0]>=bb_high) return true;           
   return false;
}  

bool Buy_Alert_3()
{
   double bb_low=iBands(NULL,0,BB_Period,2,0,PRICE_CLOSE,MODE_LOWER,0);
   //Print("bb_low[",bb_low,"] low[",Low[0],"]");
   if(Low[0]<=bb_low)  return true;   
   return false;
}
bool Sell_Alert_5()
{
   if(Sell_Alert_1()) return true;           
   return false;
}  

bool Buy_Alert_5()
{
   if(Buy_Alert_1())  return true;   
   return false;
}
//+------------------------------------------------------------------+
//|   Place Order Buy                                                |
//+------------------------------------------------------------------+

bool Buy_Order(double lot, string comment, int sl_type, double _slf,double _slv, int tp_type, double _tpf, double _tpv,int order_type)
{
   double point= MarketInfo(Symbol(), MODE_POINT);
   int digit = (int)MarketInfo(Symbol(), MODE_DIGITS);
   int ticket =OrderSend(_Symbol, order_type,lot, Ask, Slippage, 0,0,comment, Magic_Number );
   double atr =iATR(Symbol(),0, ATR_Period,0);
   double minsl= MarketInfo(Symbol(),MODE_STOPLEVEL);
   double min_sl= /*minsl*_point;*/
   NormalizeDouble(minsl*Point,Digits);
   double sl=0.0, tp= 0.0;
   double mid= iBands(NULL,0,BB_Period,2,0,PRICE_CLOSE,MODE_MAIN,1);
   Print("Minimum Broker SL: ",min_sl,"_Point",_point, " Point",_Point);
   
   if(Ticket_Check(ticket) == true)
   {
      switch(sl_type)
      {
         case 0:
               sl = Bid - (_slf * point);
               Print("Stop Loss [",sl,"]");
               break;
         case 1:
               sl =Bid - (atr * _slv);
               Print("Stop Loss [",sl,"]");
               break;
         default :
                 Print("Error in SL Type. [",sl_type,"]");
                 break;             
      }
      switch(tp_type)
      {
         case 0:
               tp = Ask + (_tpf * point);
               Print("Case 0 fix: Tp[",tp,"]");
               break;
         case 1:
               tp =Ask + (atr * _tpv);
               Print("Case 1 atr: Tp[",tp,"]");
               break;
         case 2:
               
               Print("Mid Band: ",mid);         
               tp=  mid;
               Print("Case 3: mid Tp[",tp,"]");
               break;
         default :
                 Print("Error in Tp Type. [",tp_type,"]");
                 break;
      }
      if(Bid-sl>=min_sl)
      {      
         if(Set_Order_Limit(Blue,ticket, sl,tp))return true;   
      }
     if(Bid-sl<min_sl)
      {  
        double toAdd= min_sl +(55*point);      
        sl= Bid - toAdd;
        Print("SL below Minimum Broker SL. Aplying minimum SL!Sl[",sl,"]");
        if(Set_Order_Limit(Blue,ticket, sl,tp)){return true;}
      }
   }    
  return false;
}

bool Place_Buy_Order4()
{
   double sl=0.0,tp=0.0;
   double point= MarketInfo(Symbol(), MODE_POINT);
   int ticket= OrderSend(_Symbol,OP_BUY,LotSize4,Ask,Slippage,0,0,Strat_Name4,Magic_Number);
   double atr=iATR(Symbol(),0,ATR_Period,0);   Print("ATR Reading: ",atr);
   double minSL= MarketInfo(Symbol(),MODE_STOPLEVEL);
   minSL= minSL*point;
   Print("Minimum Broker SL: ",minSL);
   
   if(Ticket_Check(ticket)==true)
   {
      order3Open=true;
      if(SL_Type2==0)
      {
         sl=SL_Fixed2*point;
         sl=Ask-sl;
      }
      if(SL_Type2==1)
      {        
        sl=atr*SL_Volatility_Factor2;
        sl= Ask-sl;
      }
      if(TP_Type2==0)
      {
         Print("Fixed TP");
         tp=TP_Fixed2*point;
         tp= Ask+tp;
      }
      if(TP_Type2==1)
      {
        tp=atr* TP_Volatility_Factor2;
        tp=Ask+tp;
      }  
      if(TP_Type2==2)
      {
         double B_Mid_B;
         B_Mid_B= iBands(NULL,0,BB_Period,2,0,PRICE_CLOSE,MODE_MAIN,1);       
         tp=B_Mid_B;
         Print("Mid Band TP: ",tp);
      }      
   }
   Print("Ask: ",Ask);
   Print("Point: ",point);
   Print("SL: ",sl);
   Print("TP:",tp);
   Print("StopLoss Level: ",Bid-sl);
  if(Ask-sl>=minSL)
   {      
      if(Set_Order_Limit(Blue,ticket, sl,tp)){return true;}   
   }
   if(Ask-sl<minSL)
   {  
      double toAdd= minSL +(10.0 * point);      
      sl= Ask- toAdd;      
      Print("SL below Minimum Broker SL. Aplying minimum SL!");
      if(Set_Order_Limit(Blue,ticket, sl,tp)){return true;}
   }
   return false;
}


bool Ticket_Check(int ticket)
{
   if(ticket<0)
   {         
      Print("OrderSend failed with error #",GetLastError());
      return false;
   }
      else
      {
         Print("OrderSend placed successfully");
         return true;
      }
   return false;
}
//+------------------------------------------------------------------+
//|   Place Order Sell                                               |
//+------------------------------------------------------------------+

bool Sell_Order(double lot, string comment, int sl_type, double _slf,double _slv, int tp_type, double _tpf, double _tpv, int order_type)
{
   double point= MarketInfo(Symbol(), MODE_POINT);
   int digit=(int) MarketInfo(Symbol(), MODE_DIGITS);
   int ticket =OrderSend(_Symbol, order_type,lot, Bid, Slippage, 0,0,comment, Magic_Number );
   double atr =iATR(Symbol(),0, ATR_Period,0);
   double minsl= MarketInfo(Symbol(),MODE_STOPLEVEL);
   minsl= minsl*_point;
   double sl=0.0, tp= 0.0;
   double mid= iBands(NULL,0,BB_Period,2,0,PRICE_CLOSE,MODE_MAIN,1);
   if(Ticket_Check(ticket) == true)
   {
      switch(sl_type)
      {
         case 0:
               sl = Bid + (_slf * point);
               Print("Stop Loss [",sl,"]");
               break;
         case 1:
               sl =Bid + (atr * _slv);
               Print("Stop Loss [",sl,"]");
               break;           
      }
      switch(tp_type)
      {
         case 0:
               tp = Bid - (_tpf * point);
               Print("Case 0: fix Tp[",tp,"]");
               break;
         case 1:
               tp =Bid - (atr * _tpv);
               Print("Case 1: atr Tp[",tp,"]");
               break;
         case 2:
               
               Print("Mid Band: ",mid);         
               tp=  mid;
               Print("Case 1: mid Tp[",tp,"]");
               break;

      }
      if( sl - Ask >= minsl && tp)
      {      
         if(Set_Order_Limit(Blue,ticket, sl,tp))return true;   
      }
     if(sl - Ask < minsl)
      {  
         double toAdd= minsl +(7.0*point);      
         sl= Ask+ toAdd;      
         Print("SL below Minimum Broker SL. Aplying minimum SL!Sl[",sl,"]");
         if(Set_Order_Limit(Blue,ticket, sl,tp)){return true;}
      }
   }    
  return false;
}

bool Place_Sell_Order4()
{
   double point=MarketInfo(Symbol(), MODE_POINT);
   int digit = (int)MarketInfo(Symbol(), MODE_DIGITS);
   double sl=0.0,tp=0.0;
   int ticket= OrderSend(_Symbol,OP_SELL,LotSize4,Bid,Slippage,0,0,Strat_Name4,Magic_Number);
   double atr=iATR(Symbol(),0,ATR_Period,0);
   double minSL= MarketInfo(Symbol(),MODE_STOPLEVEL);
   minSL= minSL*_point;
   Print("Minimum Broker SL: ",minSL);
   Print("ATR Reading: ",atr);
   if(Ticket_Check(ticket)==true)
   {
      if(SL_Type4==0)
      {
        sl=SL_Fixed4*point;
        sl=Bid+sl;
      }
      if(SL_Type4==1)
      {
        sl=atr*SL_Volatility_Factor4;
        sl= Bid+sl;
      }
      if(TP_Type4==0)
      {
        tp=TP_Fixed4*point;
        tp= Bid-tp;
      }
      if(TP_Type4==1)
      {
        
        tp=atr* TP_Volatility_Factor4;
        tp=Bid-tp;
      }
      if(TP_Type4==2)
      {
         double price=0.0;
         if(OrderSelect(ticket, SELECT_BY_TICKET)){
         price=OrderOpenPrice();}
         double B_Mid_B;
         B_Mid_B= iBands(NULL,0,BB_Period,2,0,PRICE_CLOSE,MODE_MAIN,1);
         Print("Price: ",price);        
         if(Mid_Price >0.0){
         tp= NormalizeDouble( B_Mid_B, digit);
         Print("Price: ",B_Mid_B );         
         
          }
         else{
            tp= iBands(NULL,0,BB_Period,2,0,PRICE_CLOSE,MODE_MAIN,1);
            Print("TP Mid Band: Sell. Mid Band TP: ",tp);         
         }
      }      
      Print("Estm SL: ",sl);
   if(sl-Bid>=minSL)
   {      
      if(Set_Order_Limit(Red,ticket, sl,tp)){return true;}   
   }
    if(sl-Bid<minSL)
   {
      double toAdd= minSL +(7.0*point);      
      sl= Bid + toAdd;
      NormalizeDouble(sl, digit);
      Print("Below Min Broker SL");
      Print("SL Changed"); 
      if(Set_Order_Limit(Red,ticket, sl,tp)){return true;}
   }
   
   else
   {
      return false;
   }
   }
   return false;
}
//+------------------------------------------------------------------+
//|   Modify Order                                                   |
//+------------------------------------------------------------------+
bool Set_Order_Limit(color c,int ticket,double sl, double tp)
{
   int digit = (int)MarketInfo(Symbol(), MODE_DIGITS);
   NormalizeDouble(sl, digit);
   NormalizeDouble(tp,digit);
   bool res=OrderModify(ticket,OrderOpenPrice(),sl,tp,c);
   if(ModifyCheck(res)){return true;}   
   return false;
}
bool ModifyCheck(bool res)
{
    if(!res)
      {
         Print("Error in OrderModify. Error code=",GetLastError());
         return false;
      }
      else
      {
         Print("Order modified successfully.");
         return true;
      }
}  

bool Check_Market(string strat)
{
   for(int i=0;i<4;++i)
   {
      if(OrderSelect(i, SELECT_BY_POS))
         {
            if(OrderMagicNumber()==Magic_Number && OrderSymbol() == Symbol())
            if(StringFind(OrderComment(), strat,0)!=-1)return true;
         }
   }
   return false;
}

void Check_Market()
{
   if(Check_Market(Strat_Name))order1Open=true;
   if(Check_Market(Strat_Name1v2))order1v2Open=true;
   if(Check_Market(Strat_Name2))order2Open=true;
   if(Check_Market(Strat_Name3))order3Open=true;
   if(!Check_Market(Strat_Name4))order4Open=false;
   if(!Check_Market(Strat_Name2))order2Open=false;
   if(!Check_Market(Strat_Name))order1Open=false;
   if(!Check_Market(Strat_Name1v2))order1v2Open=false;
   if(!Check_Market(Strat_Name3))order3Open=false;
   if(!Check_Market(Strat_Name4))order4Open=false;
}
bool Order_Ignore(int i,string comment, int gap, bool & flag, int _op)
{
    int total = OrdersHistoryTotal();
   if(OrderSelect(total-i,SELECT_BY_POS,MODE_HISTORY)==true)
       {
         if(OrderMagicNumber() == Magic_Number && OrderSymbol() == Symbol())
         {
            if(StringFind(OrderComment(), comment,0)!=-1)
            {
               if( (OrderProfit()<0) == true)
               {          
                     if(OrderType() == _op )
                     {
                        flag= true;
                        if(flag== true)
                        {  
                           double dif= NormalizeDouble(Time[0]-OrderCloseTime(),(int)MarketInfo(Symbol(), MODE_DIGITS)) ;
                           if(dif>= gap*60){ flag=false;}
                        }  
                        return true;                  
                     }
                    return false;
               }
            }
          }  
          return false;
       } 
   return false;
}
bool Order_Ignore(string comment, int gap, bool &  flag, int _op)
{
   for(int i=1;i<3;i++)
   {
      if(Order_Ignore(i, comment,gap,flag,_op)== true)return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//|   Trailing Stop                                                  |
//+------------------------------------------------------------------+
bool Trailing_Stop(bool chck, string comment, int trail)
{
   double point= MarketInfo(Symbol(), MODE_POINT);
   if (chck == false)
    {  return false;}
    
   else{for (int i= 0; i< OrdersTotal(); i++)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES) == true)
         {     
            if( OrderSymbol() == Symbol() && OrderMagicNumber() == Magic_Number )
               {
                  if(StringFind(OrderComment(), comment,0)!= -1)
                     {
                     
                        if(OrderType() == OP_BUY) 
                           {                           
                              if(Bid-OrderOpenPrice() > trail*point)
                                 {
                                    if(OrderStopLoss() < Bid - trail*point)
                                       {Trail(Bid - trail*point);Print("Trailing Buy....");return true;}
                                 }                              
                           }   
                         else if(OrderType() == OP_SELL) 
                           {
                              if(OrderOpenPrice() - Ask > trail *_point)
                                 {
                                     if(OrderStopLoss() > Ask + trail * point || OrderStopLoss()==0)
                                       {Trail(Ask+trail * point);Print("Trailing Sell....");return true;}
                                 }
                                 else return false;                              
                            } 
                     }   
                    else 
                     return false;           
                }
         }
   }}
   return false;
}
bool Trailing_Stop_Revised(bool chck, string comment, int trail)
{
   double point =MarketInfo(Symbol(),MODE_POINT);
   int    min_stop =(int) MarketInfo(Symbol(),MODE_STOPLEVEL);
   if (chck == false)
    {  return false;}
   else
   {
   if(trail<min_stop)
   {
      Print("Error Trail.Below Minimum allowed.\nMinimum Allowed[",min_stop,"]");
      return false;
   }
   for (int i= 0; i< OrdersTotal(); i++)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES) == true)
         {     
            if( OrderSymbol() == Symbol() && OrderMagicNumber() == Magic_Number )
               {
                  if(StringFind(OrderComment(), comment,0)!= -1)
                     {
                     
                        if(OrderType() == OP_BUY) 
                           {
                               /*Logic:
                                if stoploss above order open price
                                 if current price - sl > trail*point
                                    then trail by half the trail
                                 elseif current price minus open price >= trail * point
                                        and sl below order open price   
                                    then trail by half the trail
                                    */
                               if(OrderProfit()> 0)
                               {
                                  if(OrderStopLoss()> OrderOpenPrice() )
                                  {
                                    if(Bid-OrderStopLoss()>= trail * point)
                                       {
                                          double trailStop= trail- trail*0.25;
                                          double stop = NormalizeDouble(Bid- trailStop* point,(int)MarketInfo(Symbol(), MODE_DIGITS));
                                          Print("Trail by points[",trailStop,"]");
                                          Trail(stop);
                                       }
                                  } 
                                  else if(Bid - OrderOpenPrice()>=trail *point  
                                          && OrderStopLoss()< OrderOpenPrice() )
                                       {
                                          double trailStop= trail- trail*0.25;
                                          double stop = NormalizeDouble(Bid- trailStop* point,(int)MarketInfo(Symbol(), MODE_DIGITS));
                                          Print("Trail by points[",trailStop,"]");
                                          Trail(stop);                                       
                                       } 
                               
                               }                                
                              /*if(Bid-OrderOpenPrice() > trail*_point)
                                 {
                                    if(OrderStopLoss() < Bid - trail*_point)
                                       {Trail(Bid - trail*_point);Print("Trailing Buy....");return true;}
                                 }*/                              
                           }   
                         else if(OrderType() == OP_SELL) 
                           {
                              if(OrderProfit()> 0)
                               {
                                  if(OrderStopLoss()< OrderOpenPrice() )
                                  {
                                    if(OrderStopLoss()- Ask>= trail * point)
                                       {
                                          double trailStop= trail- trail*0.25;
                                          double stop = NormalizeDouble(Ask+ trailStop* point,(int)MarketInfo(Symbol(), MODE_DIGITS));
                                          Print("Trail by points[",trailStop,"]");
                                          Trail(stop);
                                       }
                                  } 
                                  else if( ( OrderOpenPrice() - Ask >=trail *point  &&
                                          OrderStopLoss()> OrderOpenPrice() ) || OrderStopLoss() ==0 )
                                    {
                                       double trailStop= trail- trail*0.25;
                                       double stop = NormalizeDouble(Ask+ trailStop* point,(int)MarketInfo(Symbol(), MODE_DIGITS));
                                       Print("Trail by points[",trailStop,"]");
                                       Trail(stop);                                       
                                    } 
                               
                               }
                              /*if(OrderOpenPrice() - Ask > trail *_point)
                                 {
                                     if(OrderStopLoss() > Ask + trail * _point || OrderStopLoss()==0)
                                       {Trail(Ask+trail * _point);Print("Trailing Sell....");return true;}
                                 }*/
                                 //else return false;                              
                            } 
                     }   
                    else 
                     return false;           
                }
         }
   }
   }
   return false;
}

bool Trail(double sl)
{
   Print("Trailing....");
   bool tckt= OrderModify(OrderTicket(), OrderOpenPrice(),sl,OrderTakeProfit(),0,clrNONE);
   if(!tckt)
      {
         Print("Error Trail Modify: Error No[",GetLastError(),"]"); 
         return false;
      }
   return true;
}


//+------------------------------------------------------------------+
//|   Jump to breakeven                                              |
//+------------------------------------------------------------------+
bool JumpToBreakeven(bool check,string comment, int when, int by)
{
   double point = MarketInfo(Symbol(), MODE_POINT);
   int digit = (int)MarketInfo(Symbol(),MODE_DIGITS);
   if(check == false)
      return false;
   for (int i= 0; i< OrdersTotal(); i++)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES) == true)
         {     
            if( OrderSymbol() == Symbol() && OrderMagicNumber() == Magic_Number )
               {
                  if(StringFind(OrderComment(), comment,0)!= -1)
                     {
                        if(OrderType() == OP_BUY) 
                           {   
                           //if stoploss below open price then ignore
                           //else if 
                              if(OrderStopLoss()< OrderOpenPrice())
                              {                        
                                 if( Bid-OrderOpenPrice() >= when *point)
                                    {
                                       Print("Buy Jump to Breakeven");
                                       double sl= NormalizeDouble(OrderOpenPrice()+ by *point,digit);
                                       JumpToBreakeven(OrderTicket(), sl);
                                    }
                              }                              
                           }   
                         else if(OrderType() == OP_SELL) 
                           {
                              if(OrderStopLoss()> OrderOpenPrice())
                              {
                                 if( OrderOpenPrice() - Ask >= when *point)
                                    {
                                       Print("Sell Jump to Breakeven");
                                       double sl= NormalizeDouble(OrderOpenPrice() - by *point,digit);
                                       JumpToBreakeven(OrderTicket(),sl);
                                    }
                              }
                                                 
                            } 
                     }           
                }
         }
   }
   return false;

}
bool JumpToBreakeven(int tickt, double sl)
{
   bool tckt= OrderModify(tickt, OrderOpenPrice(),sl,OrderTakeProfit(),0,clrNONE);
   if(!tckt)
      {
         Print("Error Trail Modify: Error No[",GetLastError(),"]"); 
         return false;
      }
   return true;

}


//+------------------------------------------------------------------+
//| Reversal                                                         |
//+------------------------------------------------------------------+

void SetHighest(double & h, int risk, bool chck)
{
   if(chck == false) return;
   h=0.0;
   for(int i= risk; i>0;i--)
   {
      if(High[i]> h)
      {
         h= High[i];
      }
   
   }
   Print("highest[",h,"]");
}
void SetLowest(double & h, int risk, bool chck)
{
    if(chck == false) return;
   h=Ask;
   for(int i= risk; i>0;i--)
   {
      if(Low[i]< h)
      {
         h= Low[i];
      }
   
   }
   Print("Lowest[",h,"]");
}
//+------------------------------------------------------------------+
//| Market Close                                                     |
//+------------------------------------------------------------------+

bool MarketClose(string comment, double low, double high)
{
for (int i= 0; i< OrdersTotal(); i++)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES) == true)
         {     
            if( OrderSymbol() == Symbol() && OrderMagicNumber() == Magic_Number )
               {
                  if(StringFind(OrderComment(), comment,0)!= -1)
                     {
                        if(OrderType() == OP_BUY) 
                           { 
                              if(Bid<= low)
                                 {
                                    Print("Close Order. Risk Management");
                                    bool res=OrderClose(OrderTicket(),OrderLots(),Bid,Slippage,clrAntiqueWhite);
                                    ModifyCheck(res);
                                    return true;
                                 }                              
                           }   
                         else if(OrderType() == OP_SELL) 
                           {
                             if(Ask >= high)
                                 {
                                    Print("Close Order. Risk Management");
                                    bool res=OrderClose(OrderTicket(),OrderLots(),Ask,Slippage,clrAntiqueWhite);
                                    ModifyCheck(res);
                                    return true;
                                 }
                                 else return false;                              
                            } 
                     }   
                    else 
                     return false;           
                }
         }
   }
   return false;
}
bool riskManagementClose(bool check,string comment, int gap)
{
   if(check ==false)
      return false;
      
   int total = OrdersTotal();
   for(int i=0; i<total;i++)
      {
         if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true)
          {
            if(OrderMagicNumber() == Magic_Number && OrderSymbol() == Symbol())
            {
               if(StringFind(OrderComment(), comment,0)!=-1)
               {
                 
                 double dif= NormalizeDouble( Time[0]-OrderOpenTime(), (int)MarketInfo(Symbol(), MODE_DIGITS) );
                 if(dif>= gap*60)
                 { 
                   Print("Inside risk Management Close");
                   MarketClose(OrderTicket(), OrderLots());
                 }
               }               
            }             
            return false;
           }
      }           
   return false;
}
bool MarketClose(int tick, double lots)
{

   if(OrderType() == OP_BUY) 
     {                              
         Print("Close Order. Risk Management");
         bool res=OrderClose(tick,lots,Bid,Slippage,clrAntiqueWhite);
         ModifyCheck(res);
         return true;                                                             
     }   
  else if(OrderType() == OP_SELL) 
     {
         
         Print("Close Order. Risk Management");
         bool res=OrderClose(tick,lots,Ask,Slippage,clrAntiqueWhite);
         ModifyCheck(res);
         return true;
    }
   return false;
}


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+

int OnInit()
  {
//---
   _point= MyPoint();   
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   Check_Market();
   if(order1Open)
      {
         Trailing_Stop_Revised(_trail1,Strat_Name, _trailPoint1);
         JumpToBreakeven(_breakEven1,Strat_Name,_whenJump1,_jumpBy1);
         if(_use_risk_candle1)MarketClose(Strat_Name,_lowestStop1, _highestStop1);
         riskManagementClose(_gapCloseCheck1,Strat_Name,_whenClose1);

      }
    if(order1v2Open)
      {
         Trailing_Stop_Revised(_trail1v2,Strat_Name1v2, _trailPoint1v2);
         JumpToBreakeven(_breakEven1v2,Strat_Name1v2,_whenJump1v2,_jumpBy1v2);
         if(_use_risk_candle1v2)MarketClose(Strat_Name1v2,_lowestStop1v2, _highestStop1v2);
         riskManagementClose(_gapCloseCheck1v2,Strat_Name1v2,_whenClose1v2);

      }
   if(order2Open)
      {
         Trailing_Stop_Revised(_trail2 ,Strat_Name2, _trailPoint2);
         JumpToBreakeven(_breakEven1,Strat_Name2,_whenJump2,_jumpBy2);
         if(_use_risk_candle2)MarketClose(Strat_Name2,_lowestStop2, _highestStop2);
         riskManagementClose(_gapCloseCheck2,Strat_Name2,_whenClose2);
      }
   if(order3Open)
      {
         Trailing_Stop_Revised(_trail3, Strat_Name3, _trailPoint3);
         JumpToBreakeven(_breakEven3,Strat_Name3,_whenJump3,_jumpBy3);
         if(_use_risk_candle3)MarketClose(Strat_Name3,_lowestStop3, _highestStop3);
         riskManagementClose(_gapCloseCheck3,Strat_Name3,_whenClose3);
      }
   if(order4Open)
   {
      Trailing_Stop_Revised(_trail4, Strat_Name4, _trailPoint4);
      JumpToBreakeven(_breakEven4,Strat_Name4,_whenJump4,_jumpBy4);
      if(_use_risk_candle4)MarketClose(Strat_Name4,_lowestStop4, _highestStop4);
      riskManagementClose(_gapCloseCheck4,Strat_Name4,_whenClose4);     
   }

   if(IsNewBar())
      {
        if(useStrategy1)
        {
         Order_Ignore(Strat_Name,_timegap1,buyIgnore1,OP_BUY);
         Order_Ignore(Strat_Name,_timegap1,sellIgnore1,OP_SELL);   
         if(Pattern1()==BUY && !sellIgnore1==true)
         {
             Sell_Order(LotSize,Strat_Name,SL_Type,SL_Fixed,SL_Volatility_Factor,
                       TP_Type,TP_Fixed,TP_Volatility_Factor,OP_SELL);
                       SetLowest(_lowestStop1, _risk_candle1, _use_risk_candle1);
             buyIgnore1=false;
         }
         if(Pattern1()==SELL && !buyIgnore1==true)
            {
               Buy_Order(LotSize,Strat_Name,SL_Type,SL_Fixed,SL_Volatility_Factor,
                          TP_Type,TP_Fixed,TP_Volatility_Factor,OP_BUY);
               SetHighest(_highestStop1, _risk_candle1, _use_risk_candle1);           
               sellIgnore1=false;
            }
        } 
        if(useStrategy1v2)
        {
         Order_Ignore(Strat_Name1v2,_timegap1v2,buyIgnore1v2,OP_BUY);
         Order_Ignore(Strat_Name1v2,_timegap1v2,sellIgnore1v2,OP_SELL);   
         if(Pattern1v2()==BUY && !buyIgnore1v2==true)
         {
             Sell_Order(LotSize1v2,Strat_Name1v2,SL_Type1v2,SL_Fixed1v2,SL_Volatility_Factor1v2,
                        TP_Type1v2,TP_Fixed1v2,TP_Volatility_Factor1v2,OP_SELL);
                       SetLowest(_lowestStop1v2, _risk_candle1v2, _use_risk_candle1v2);
             buyIgnore1=false;
         }
         if(Pattern1v2()==SELL && !buyIgnore1v2==true)
            {
               Buy_Order(LotSize1v2,Strat_Name1v2,SL_Type1v2,SL_Fixed1v2,SL_Volatility_Factor1v2,
                          TP_Type1v2,TP_Fixed1v2,TP_Volatility_Factor1v2,OP_BUY);
               SetHighest(_highestStop1v2, _risk_candle1v2, _use_risk_candle1v2);           
               sellIgnore1=false;
            }
        } 
        if(useStrategy2)
        {
         Order_Ignore(Strat_Name2,_timegap2,buyIgnore2,OP_BUY);
         Order_Ignore(Strat_Name2,_timegap2,sellIgnore2,OP_SELL); 
         if(Pattern2()==BUY && sellIgnore2==false)
            {
                Sell_Order(LotSize2,Strat_Name2,SL_Type2,SL_Fixed2,SL_Volatility_Factor2,
                          TP_Type2,TP_Fixed2,TP_Volatility_Factor2,OP_SELL);
                SetLowest(_lowestStop2, _risk_candle2, _use_risk_candle2);
                buyIgnore2=false;
            }
         else if(Pattern2()==SELL && buyIgnore2==false)
            {
               Buy_Order(LotSize2,Strat_Name2,SL_Type2,SL_Fixed2,SL_Volatility_Factor2,
                          TP_Type2,TP_Fixed2,TP_Volatility_Factor2,OP_BUY);
               SetHighest(_highestStop2, _risk_candle2, _use_risk_candle2);
               sellIgnore2=false;
            }
        }         
       if(useStrategy3 )
        {
         Order_Ignore(Strat_Name3,_timegap3,buyIgnore3,OP_BUY);
         Order_Ignore(Strat_Name3,_timegap3,sellIgnore3,OP_SELL); 
         if(Pattern3()==BUY && sellIgnore3==false)
            { 
               Sell_Order(LotSize3,Strat_Name3,SL_Type3,SL_Fixed3,SL_Volatility_Factor3,
                          TP_Type3,TP_Fixed3,TP_Volatility_Factor3,OP_SELL);
               SetLowest(_lowestStop3, _risk_candle3, _use_risk_candle3);
               buyIgnore3=false;
            }
         else if(Pattern3()==SELL && buyIgnore3==false)
            {
               Buy_Order(LotSize3,Strat_Name3,SL_Type3,SL_Fixed3,SL_Volatility_Factor3,
                          TP_Type3,TP_Fixed3,TP_Volatility_Factor3,OP_BUY);
               SetHighest(_highestStop3, _risk_candle3, _use_risk_candle3);
               sellIgnore3=false; 
            }
        } 
        if(useStrategy4)
        {
         double mid= iBands(NULL,0,BB_Period,2,0,PRICE_CLOSE,MODE_MAIN,1);
         double top1= iBands(NULL,0,BB_Period,2,0,PRICE_CLOSE,MODE_UPPER,2);
         double bot1= iBands(NULL,0,BB_Period,2,0,PRICE_CLOSE,MODE_LOWER,2);
         double top2=iBands(NULL,0,BB_Period,2,0,PRICE_CLOSE,MODE_UPPER,1);
         double bot2= iBands(NULL,0,BB_Period,2,0,PRICE_CLOSE,MODE_LOWER,1);
         Order_Ignore(Strat_Name4,_timegap4,buyIgnore4,OP_BUY);
         Order_Ignore(Strat_Name4,_timegap4,sellIgnore4,OP_SELL); 
         if(!order4Open)
         {
            //Pattern4();
            if(Close[2]< bot1 && flag_s == false)
            {
               flag_s=true;
            }
            else if(Close[2]> top1 && flag_b==false)
            {
               flag_b =true;
            }
            if(flag_s==true)
            {
               if(Close[1]< bot2 || High[1]>= mid)
                  {
                     flag_s= false;
                     count_s= 0;
                     Print("flag_s[",flag_s,"] count_s[",count_s,"]");
                  }
               else if(Close[1]> bot2 && High[1] < mid)
               {
                  flag_s= true;
                  count_s+=1;
                  Print("flag_s[",flag_s,"] count_s[",count_s,"]");
               }          
            }
            
            else if(flag_b ==true)
            {
               if(Close[1]> top2 || Low[1]>= mid)
                  {
                     flag_b= false;
                     count_b= 0;
                     Print("flag_b[",flag_b,"] count_b[",count_b,"]");
                  }
               else if(Close[1]< top2 && Low[1] > mid)
               {
                  flag_b= true;
                  count_b+=1;
                  Print("flag_b[",flag_b,"] count_b[",count_b,"]");
               }         
            }
            Pattern4(flag_b,count_b,flag_s,count_s, _highestStop4, _lowestStop4,_risk_candle4 );
         }
        } 

      }
  }
//+------------------------------------------------------------------+
