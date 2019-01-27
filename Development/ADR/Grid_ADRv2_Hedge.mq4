
//+------------------------------------------------------------------+
//|                                             Grid_ADRv2_Hedge.mq4 |
//|                        Copyright 2017, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#define _TRUE  1
#define _FALSE -1
#define FAIL  -11
#define BUY   2
#define SELL  3

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum Take_Profit_Type
  {

   FIXED       = 0,
   VOLATILITY  = 1,
   MID_BB      = 2,
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum Strategy_Type
  {
   BREAKOUT    = 0,
   BREAKIN     = 1,
   BANDTOUCH   = 2,
  };
  
enum Entry_Type
   {
    BREAK      = 0, //Break Based
    ADR      = 1, //Point Based/ADS
    INVERSE    =-1, //Inverse 
   };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum _type
  {
   INCREASE = 1,// Increase
   DECREASE = 0,// Decrease
   SAME = 2,// Same
  };
bool                   flag_b=false;
bool                   flag_s=false;
bool                   buyIgnore1=false;
bool                   sellIgnore1=false;
double                 _highestStop1;
double                 _lowestStop1;
int                    buy_counter=0;
int                    sell_counter=0;
input int              Magic_Number = 1;                 //Magic Number
int                    p_Magic_Number=Magic_Number+1;
extern string          order1="-------Order_1--------";  //Order 1 Settings
bool                   order1Open=false;
extern string          Strat_Name1="Grid";                //Strategy Name
input bool             useStrategy1=true;                 //Use Strategy
input Entry_Type       entry_type = 0;                    //Entry Type
input int              numberOfLegs=0;                    //Number of Legs
input double           startLot=0.1;                      //Starting lots
input bool             useGridding=true;                  //Use Gridding
input _type            legIncreaseDecrease=INCREASE;      //Increase or decrease lot size on each leg. 1 = increase 0=decrease 
input int              increaseLLotBy  = 2;               //Lot Size ratio to increase each leg by(in multiples)
input int              decreaseLLotBy  = 2;               //Lot Size ratio to decrease each leg by(in multiples)
input double           points = 30;                       //ADR::Points fo next Entry
input Take_Profit_Type TP_Type1 = VOLATILITY;             //TP Type
input Take_Profit_Type SL_Type1= VOLATILITY;              //SL Type
input double           TP_Volatility_Factor1=2.0;         //TP::Volatility Factor
input double           SL_Volatility_Factor1=1.0;         //SL:: Volatility Factor
input double           TP_Fixed1=25.0;                    //TP:: Fixed(Points)
input double           SL_Fixed1=12.0;                    //SL:: Fixed(Points)
input bool             EQ_Based=true;                     //Use Equity Based TP
input bool             useGridStop=false;                 //Us Equity Based SL
input bool             LG_Based=false;                    //Use Leg Based TP
input double           _profitTarget=1000;                //Profit Target
input double           _stopLevel=-500.0;                 //Stop Out Level
input string           s_CutReverse="Cut And Reverse";    //Cut and Reverse Settings
input bool             useReverseAndCut = false;           //Use Reverse And Cut

input Take_Profit_Type TP_Type2 = VOLATILITY;             //TP Type
input Take_Profit_Type SL_Type2= VOLATILITY;              //SL Type
input double           TP_Volatility_Factor2=2.0;         //TP::Volatility Factor
input double           SL_Volatility_Factor2=1.0;         //SL:: Volatility Factor
input double           TP_Fixed2=25.0;                    //TP:: Fixed(Points)
input double           SL_Fixed2=12.0;                    //SL:: Fixed(Points)

input int              _timegap1=31;                     //Order 1:: time gap(in mins)
input bool             _trail1 = false;                  //Use Trailing Stop
input int              _trailPoint1;                     //Trail::When(in Points)
input bool             _breakEven1 = false;              //Use Jump to Breakeven
input int              _whenJump1=25;                    //Breakeven::When(in Points)
input int              _jumpBy1=6;                       //Breakeven::Points to add
input bool             _use_risk_candle1=false;           //Use Risk Management
input int              _risk_candle1=4;                  //Risk Management:: Number of candles
input bool             _gapCloseCheck1=false;             //Use Close Order After certain Time
input int              _whenClose1=50;                   //Close Order::Time gap in minutes 
input double           risk=2;                           //Risk Percentage
double                 prevLotBuy=0.0;
double                 prevLotSell=0.0;
extern string          bb_Set="--Bollinger Band Settings--"; //Bollinger Band:: Settings
input ENUM_TIMEFRAMES  BB_Chart_Timeframe=PERIOD_CURRENT;  //Bollinger Band:: Chart Time 
input int              BB_Period=14;                       //Bollinger Band:: Period

extern string          atr_Set="--ATR Settings--";        //ATR::Settings
input int              ATR_Period=14;                     //ATR::Period 
input ENUM_TIMEFRAMES  ATR_Charts_Period=PERIOD_CURRENT;  //ATR::Chart Time

extern string          adr_Set="--ADR Settings--";        //ADR::Settings
input int              ADR_Period=14;                     //ADR::Period 
input ENUM_TIMEFRAMES  ADR_Charts_Period=PERIOD_D1;       //ADR::Chart Time
input double           target_ADRH=20;                    //ADR::Target for High
input double           target_ADRL=-125;                  //ADR::Target for Low

input int              Slippage=33;                       //Slippage

int count_b,count_s;
double _point;
double Mid_Price=0.0;
//list <int> BuyTickets;

double MyPoint()
  {
   double CalcPoint=0;
   if(_Digits==2 || _Digits==3) CalcPoint=0.01;
   else if(_Digits==4 || _Digits==5) CalcPoint=0.0001;
   return(CalcPoint);
  }
//+------------------------------------------------------------------+
//|                                                                  |
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
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int TotalOpenOrder()
  {
   int total_order=0;
   for(int order=0; order<OrdersTotal();order++)
     {
      if(OrderSelect(order,SELECT_BY_POS,MODE_TRADES)==false)break;
      if(OrderMagicNumber()==Magic_Number && OrderSymbol()==_Symbol)
        {
         total_order++;
        }
     }
   return(total_order);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int Pattern1()
{
  if(Sell_Alert_1()) return SELL;
  else if(Buy_Alert_1()) return BUY;
  return FAIL;
}

int Pattern_Point()
{
  int digit =(int) MarketInfo(Symbol(), MODE_DIGITS);
  int total =OrdersTotal();
  if(OrderSelect(total-1,SELECT_BY_POS,MODE_TRADES)>0)
  {
   double openPrice=OrderOpenPrice();
   int    op_type= OrderType();
   if(op_type == OP_BUY)
   {
      //if(openPrice - Bid >= points)
      if(Bid -openPrice  >= NormalizeDouble(points*_Point,digit))
      {
         return BUY;
      }
   }
   if(op_type == OP_SELL)
   {
      if(openPrice-Ask >=NormalizeDouble(points*_Point,digit))
      //if(Ask-openPrice >=points)
      {
         return SELL;
      }   
   }  
  }     
  return FAIL;
}


int Pattern_Reverse()
{
  if(Sell_Alert_1()) return BUY;
  else if(Buy_Alert_1()) return SELL;
  return FAIL;
}
int Pattern_ADR()
{
   if(!entry_type == ADR)
   {return FAIL;}
   int digit = (int)MarketInfo(Symbol(),MODE_DIGITS);
   double adrHigh = CalculateAvgHigh();
   double adrLow  = CalculateAvgLow();
   double curAdrH=NormalizeDouble(iHigh(NULL,PERIOD_D1,0),digit);
   double curAdrL=NormalizeDouble(iLow(NULL,PERIOD_D1,0),digit);
   double targetH = NormalizeDouble(target_ADRH*Point,digit);
   double targetL = NormalizeDouble(target_ADRL*Point,digit);
   if(adrHigh - curAdrH<=targetH)
   {
      return SELL;
   }
   else if(curAdrL-adrLow<=targetL)
   {
      return BUY;
   }
   
   return FAIL;
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool Sell_Alert_1()
  {
   double bb_high=iBands(NULL,0,BB_Period,2,0,PRICE_CLOSE,MODE_UPPER,1);
   if(Open[1]<bb_high && Close[1]>bb_high ) return true;
   return false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool Buy_Alert_1()
  {
   double bb_low=iBands(NULL,0,BB_Period,2,0,PRICE_CLOSE,MODE_LOWER,1);
   if(Open[1]>bb_low && Close[1]< bb_low)  return true;
   return false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool Sell_Order(double lot,string comment,int sl_type,double _slf,double _slv,int tp_type,double _tpf,double _tpv,int order_type)
  {
   int ticket=OrderSend(_Symbol,order_type,lot,Bid,Slippage,0,0,comment,Magic_Number);
   double point=MarketInfo(Symbol(),MODE_POINT);
   int digit =(int)MarketInfo(Symbol(),MODE_DIGITS);
   Print("Digits[",digit,"]");
   double atr=NormalizeDouble(iATR(Symbol(),0,ATR_Period,0),digit);
   double minsl=MarketInfo(Symbol(),MODE_STOPLEVEL);
   minsl=minsl*point;
   double sl=0.0,tp=0.0;
   double mid=iBands(NULL,0,BB_Period,2,0,PRICE_CLOSE,MODE_MAIN,1);
   if(Ticket_Check(ticket)==true)
     {
      switch(sl_type)
        {
         case 0:
            sl=Bid+(_slf*point);
            Print("Stop Loss [",sl,"]");
            break;
         case 1:
            sl=Bid+(atr*_slv);
            Print("Stop Loss [",sl,"]");
            break;
        }
      switch(tp_type)
        {
         case 0:
            tp=Bid -(_tpf*point);
            Print("Case 0: fix Tp[",tp,"]");
            break;
         case 1:
            tp=Bid -(atr*_tpv);
            Print("Case 1: atr Tp[",tp,"]");
            break;
         case 2:
            tp=mid;
            Print("Case 1: mid Tp[",tp,"]");
            break;
        }
      if(sl-Ask>=minsl && tp)
        {
         NormalizeDouble(sl,digit);
          if(useReverseAndCut)
            {
               CutAndReverse(order_type,sl,lot);
                
            }
         if(Set_Order_Limit(Blue,ticket, sl,tp))return true;
        }
      if(sl-Ask<minsl)
        {
         double toAdd=minsl+(7.0 *point);
         sl=Ask+toAdd;
         NormalizeDouble(sl,digit);
         Print("SL below Minimum Broker SL. Aplying minimum SL!Sl[",sl,"]");
          if(useReverseAndCut)
            {
               CutAndReverse(order_type,sl,lot);
                
            }
         if(Set_Order_Limit(Blue,ticket,sl,tp)){return true;}
        }
     }
   return false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool Buy_Order(double lot,string comment,int sl_type,double _slf,double _slv,int tp_type,double _tpf,double _tpv,int order_type)
  {
   int ticket=OrderSend(_Symbol,order_type,lot,Ask,Slippage,0,0,comment,Magic_Number);
   double point=MarketInfo(Symbol(),MODE_POINT);
   int digit =(int)MarketInfo(Symbol(),MODE_DIGITS);
   double atr=NormalizeDouble(iATR(Symbol(),0,ATR_Period,0),digit);
   double minsl=MarketInfo(Symbol(),MODE_STOPLEVEL);
   double min_sl=/*minsl*_point;*/
                 NormalizeDouble(minsl*point,Digits);
   double sl=0.0,tp=0.0;
   double mid=iBands(NULL,0,BB_Period,2,0,PRICE_CLOSE,MODE_MAIN,1);
   Print("Minimum Broker SL: ",min_sl,"Point",point," Point",_Point);

   if(Ticket_Check(ticket)==true)
     {
      switch(sl_type)
        {
         case 0:
            sl=Bid -(_slf*point);
            Print("Stop Loss [",sl,"]");
            break;
         case 1:
            sl=Bid -(atr*_slv);
            Print("Stop Loss [",sl,"]");
            break;
         default :
            Print("Error in SL Type. [",sl_type,"]");
            break;
        }
      switch(tp_type)
        {
         case 0:
            tp=Ask+(_tpf*point);
            Print("Case 0 fix: Tp[",tp,"]");
            break;
         case 1:
            tp=Ask+(atr*_tpv);
            Print("Case 1 atr: Tp[",tp,"]");
            break;
         case 2:

            Print("Mid Band: ",mid);
            tp=mid;
            Print("Case 3: mid Tp[",tp,"]");
            break;
         default :
            Print("Error in Tp Type. [",tp_type,"]");
            break;
        }
      if(Bid-sl>=min_sl)
        {
         NormalizeDouble(sl,digit);
         if(useReverseAndCut)
            {
               CutAndReverse(order_type,sl,lot);
            }
         if(Set_Order_Limit(Blue,ticket, sl,tp))
         {
            return true;
            
         }
        }
      if(Bid-sl<min_sl)
        {
         double toAdd=min_sl+(55*point);
         sl=Bid-toAdd;
         NormalizeDouble(sl,digit);
         Print("SL below Minimum Broker SL. Aplying minimum SL!Sl[",sl,"]");
         if(useReverseAndCut)
            {
               CutAndReverse(order_type,sl,lot);
                
            }
         if(Set_Order_Limit(Blue,ticket,sl,tp))
         {
            return true;              
         }
        }
     }
   return false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
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
//|                                                                  |
//+------------------------------------------------------------------+
bool Set_Order_Limit(color c,int ticket,double sl,double tp)
  {
   double point= MarketInfo(Symbol(),MODE_POINT);
   int digit = (int)MarketInfo(Symbol(),MODE_DIGITS);
   sl=NormalizeDouble(sl,digit);
   tp=NormalizeDouble(tp,digit);
   bool res=OrderModify(ticket,OrderOpenPrice(),sl,tp,c);
   if(ModifyCheck(res)){return true;}
   return false;
  }
bool CutAndReverse(int op, double sl, double lot)
{
   double point= MarketInfo(Symbol(),MODE_POINT);
   int digit = (int)MarketInfo(Symbol(),MODE_DIGITS);
   sl=NormalizeDouble(sl,digit);
   Print("Cut And Reverse");
   int res=0;
   if(op == OP_BUY)
   {
      //OrderSend(_Symbol,order_type,lot,Ask,Slippage,0,0,comment,Magic_Number);
      res = OrderSend(Symbol(),OP_SELLSTOP,lot,sl,Slippage,0,0,Strat_Name1,p_Magic_Number,0,clrAliceBlue);   
   }
   if(op == OP_SELL)
   {
      res = OrderSend(Symbol(),OP_BUYSTOP,lot,sl,Slippage,0,0,Strat_Name1,p_Magic_Number,0,clrAzure);   
   }
   if(Ticket_Check(res)){return true;}
   return false;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
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
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool Check_Market(string strat)
  {
   for(int i=0;i<4;++i)
     {
      if(OrderSelect(i,SELECT_BY_POS))
        {
         if( (OrderMagicNumber()==Magic_Number||OrderMagicNumber()==p_Magic_Number) && OrderSymbol()==Symbol())
            if(StringFind(OrderComment(), strat,0)!=-1)return true;
        }
     }
   return false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Check_Market()
  {
   if(Check_Market(Strat_Name1))order1Open=true;
   if(!Check_Market(Strat_Name1))order1Open=false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool Trailing_Stop(bool chck,string comment,int trail)
  {
   double point = MarketInfo(Symbol(), MODE_POINT);
   int    digit =(int)MarketInfo(Symbol(), MODE_DIGITS);
   int    minStop= (int)MarketInfo(Symbol(), MODE_STOPLEVEL);
   if(chck==false)
     {  return false;}
   else
     {
      for(int i=0; i<OrdersTotal(); i++)
        {
         if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true)
           {
            if(OrderSymbol()==Symbol() && OrderMagicNumber()==Magic_Number)
              {
               if(StringFind(OrderComment(),comment,0)!=-1)
                 {
                  if(OrderType()==OP_BUY)
                    {
                    /*Logic
                       -if above minimum Sl
                       -if difference between current price and Sl >trail
                           -then Trail(sl + the difference)
                      
                      */
                     if(Bid - OrderOpenPrice()> NormalizeDouble(minStop*point,digit))
                        {
                           double diff = NormalizeDouble(Bid - OrderStopLoss(),digit);
                           if(diff>trail*point)
                           {
                              diff= Bid-trail*point;
                              Trail(NormalizeDouble(diff,digit));
                           }
                        }
                       
                    }
                  else if(OrderType()==OP_SELL)
                    {
                        if(OrderOpenPrice()-Ask>NormalizeDouble(minStop*point,digit))
                        {
                           double diff = NormalizeDouble( OrderStopLoss()- Ask,digit);
                           if(diff>trail*point)
                           {
                              diff= Bid-trail*point;
                              Trail(NormalizeDouble(diff,digit));
                           }
                        }
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
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

bool Trailing_Stop_Revised(bool chck,string comment,int trail)
  {
   double point=MarketInfo(Symbol(),MODE_POINT);
   int    min_stop=(int) MarketInfo(Symbol(),MODE_STOPLEVEL);
   if(chck==false)
     {  return false;}
   else
     {
      if(trail<min_stop)
        {
         Print("Error Trail.Below Minimum allowed.\nMinimum Allowed[",min_stop,"]");
         return false;
        }
      for(int i=0; i<OrdersTotal(); i++)
        {
         if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true)
           {
            if(OrderSymbol()==Symbol() && OrderMagicNumber()==Magic_Number)
              {
               if(StringFind(OrderComment(),comment,0)!=-1)
                 {

                  if(OrderType()==OP_BUY)
                    {
/*Logic:
                                if stoploss above order open price
                                 if current price - sl > trail*point
                                    then trail by half the trail
                                 elseif current price minus open price >= trail * point
                                        and sl below order open price   
                                    then trail by half the trail
                                    */
                     if(OrderProfit()>0)
                       {
                        if(OrderStopLoss()>OrderOpenPrice())
                          {
                           if(Bid-OrderStopLoss()>=trail*point)
                             {
                              double trailStop=trail-trail*0.25;
                              double stop=NormalizeDouble(Bid-trailStop *point,(int)MarketInfo(Symbol(),MODE_DIGITS));
                              Print("Trail by points[",trailStop,"]");
                              Trail(stop);
                             }
                          }
                        else if(Bid-OrderOpenPrice()>=trail *point
                           && OrderStopLoss()<OrderOpenPrice())
                             {
                              double trailStop=trail-trail*0.25;
                              double stop=NormalizeDouble(Bid-trailStop *point,(int)MarketInfo(Symbol(),MODE_DIGITS));
                              Print("Trail by points[",trailStop,"]");
                              Trail(stop);
                             }

                       }
                     }
                    else if(OrderType()==OP_SELL)
                     {
                        if(OrderProfit()>0)
                          {
                           if(OrderStopLoss()<OrderOpenPrice())
                             {
                              if(OrderStopLoss()-Ask>=trail*point)
                                {
                                 double trailStop=trail-trail*0.25;
                                 double stop=NormalizeDouble(Ask+trailStop *point,(int)MarketInfo(Symbol(),MODE_DIGITS));
                                 Print("Trail by points[",trailStop,"]");
                                 Trail(stop);
                                }
                             }
                            else if(( OrderOpenPrice()-Ask>=trail *point && 
                              OrderStopLoss()>OrderOpenPrice()) || OrderStopLoss()==0)
                              {
                                 double trailStop=trail-trail*0.25;
                                 double stop=NormalizeDouble(Ask+trailStop *point,(int)MarketInfo(Symbol(),MODE_DIGITS));
                                 Print("Trail by points[",trailStop,"]");
                                 Trail(stop);
                               }

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
 }       
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
      bool Trail(double sl)
        {
         Print("Trailing....");
         bool tckt=OrderModify(OrderTicket(),OrderOpenPrice(),sl,OrderTakeProfit(),0,clrNONE);
         if(!tckt)
           {
            Print("Error Trail Modify: Error No[",GetLastError(),"]");
            return false;
           }
         return true;
        }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|   Jump to breakeven                                              |
//+------------------------------------------------------------------+
bool JumpToBreakeven(bool check,string comment,int when,int by)
{
   double point=MarketInfo(Symbol(),MODE_POINT);
   int digit=(int)MarketInfo(Symbol(),MODE_DIGITS);
   if(check == false)
      return false;
   for(int i=0; i<OrdersTotal(); i++)
     {
       if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true)
         {
           if(OrderSymbol()==Symbol() && OrderMagicNumber()==Magic_Number)
             {
               if(StringFind(OrderComment(),comment,0)!=-1)
                 {
                   if(OrderType()==OP_BUY)
                     {
                       //if stoploss below open price then ignore
                       //else if 
                       if(OrderStopLoss()<OrderOpenPrice())
                        {
                          if(Bid-OrderOpenPrice()>=when *point)
                            {
                              Print("Buy Jump to Breakeven");
                              double sl=NormalizeDouble(OrderOpenPrice()+by *point,digit);
                              JumpToBreakeven(OrderTicket(),sl);
                            }
                        }
                     }
                    else if(OrderType()==OP_SELL)
                      {
                        if(OrderStopLoss()>OrderOpenPrice())
                          {
                           if(OrderOpenPrice()-Ask>=when *point)
                             {
                              Print("Sell Jump to Breakeven");
                              double sl=NormalizeDouble(OrderOpenPrice()-by *point,digit);
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
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
      bool JumpToBreakeven(int tickt,double sl)
        {
         bool tckt=OrderModify(tickt,OrderOpenPrice(),sl,OrderTakeProfit(),0,clrNONE);
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

void SetHighest(double  &h,int irisk,bool chck)
  {
    if(chck == false) return;
    h=0.0;
    for(int i=irisk; i>0;i--)
     {
       if(High[i]>h)
        {
          h=High[i];
        }
      }
    Print("highest[",h,"]");
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SetLowest(double  &h,int irisk,bool chck)
  {
    if(chck == false) return;
    h=Ask;
    for(int i=irisk; i>0;i--)
      {
        if(Low[i]<h)
          {
            h=Low[i];
          }
      }
    Print("Lowest[",h,"]");
  }
//+------------------------------------------------------------------+
//| Market Close                                                     |
//+------------------------------------------------------------------+

bool MarketClose(string comment,double low,double high)
  {
    for(int i=0; i<OrdersTotal(); i++)
      {
        if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true)
          {
            if(OrderSymbol()==Symbol() && OrderMagicNumber()==Magic_Number)
              {
                if(StringFind(OrderComment(),comment,0)!=-1)
                 {
                   if(OrderType()==OP_BUY)
                    {
                      if(Bid<=low)
                       {
                         Print("Close Order. Risk Management");
                         bool res=OrderClose(OrderTicket(),OrderLots(),Bid,Slippage,clrAntiqueWhite);
                         ModifyCheck(res);
                         return true;
                       }
                    }
                   else if(OrderType()==OP_SELL)
                    {
                      if(Ask>=high)
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
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool riskManagementClose(bool check,string comment,int gap)
 {
   if(check==false)
    return false;

   int total= OrdersTotal();
   for(int i=0; i<total;i++)
    {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true)
       {
         if(OrderMagicNumber()==Magic_Number && OrderSymbol()==Symbol())
          {
                  if(StringFind(OrderComment(),comment,0)!=-1)
                    {

                     double dif=double(Time[0]-OrderOpenTime());
                     if(dif>=gap*60){  Print("Inside risk Management Close");MarketClose(OrderTicket(),OrderLots());}
                    }
                 }
               return false;
              }
           }
         return false;
        }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
      bool MarketClose(int tick,double lots)
        {

         if(OrderType()==OP_BUY)
           {
            Print("Close Order. Risk Management");
            bool res=OrderClose(tick,lots,Bid,Slippage,clrAntiqueWhite);
            ModifyCheck(res);
            return true;
           }
         else if(OrderType()==OP_SELL)
           {

            Print("Close Order. Risk Management");
            bool res=OrderClose(tick,lots,Ask,Slippage,clrAntiqueWhite);
            ModifyCheck(res);
            return true;
           }
         return false;
        }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool Order_Ignore(int i,string comment,int gap,bool  &flag,int _op)
 {
        
  int total=OrdersHistoryTotal();
  if(OrderSelect(total-i,SELECT_BY_POS,MODE_HISTORY)==true)
   {
     if(OrderMagicNumber()==Magic_Number && OrderSymbol()==Symbol())
      {
        if(StringFind(OrderComment(),comment,0)!=-1)
         {
           if((OrderProfit()<0)==true)
            {
              if(OrderType()==_op)
               {
                 flag=true;
                 if(flag==true)
                  {
                    double dif=double(Time[0]-OrderCloseTime());
                    if(dif>=gap*60){ flag=false;}
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
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
      bool Order_Ignore(string comment,int gap,bool   &flag,int _op)
        {
         int total=OrdersHistoryTotal();
         for(int i=1;i<3;i++)
           {
            if(Order_Ignore(i, comment,gap,flag,_op)== true)return true;
           }
         return false;
        }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
      bool OrderIgnoreCheck(int op,string comment,int  &count)
        {
         int total= OrdersTotal();
         for(int i=0; i<total;i++)
           {
            if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true)
              {
               if((OrderMagicNumber()==Magic_Number || OrderMagicNumber() == p_Magic_Number) && OrderSymbol()==Symbol())
                 {
                  if(StringFind(OrderComment(),comment,0)!=-1)
                    {
                     if(OrderType()==op)
                       {
                        return true;
                       }
                    }
                 }
              }
           }
         OrderCounterCheck(op,comment,count);
         Reset(op,buy_counter,sell_counter);
         return false;
        }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OrderCounterCheck(int op,string comment,int  &c)
 {
   int count=0;
   int total= OrdersTotal();
   if(total ==0)return;
   for(int i=0; i<total;i++)
    {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true)
       {
         if(OrderMagicNumber()==Magic_Number && OrderSymbol()==Symbol())
          {
            if(StringFind(OrderComment(),comment,0)!=-1)
             {
               if(OrderType()==op)
                {
                  count++;
                }
             }
           }
       }
    }
         c=count;

 }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Reset(int op,int &buy,int &sell)
 {
   if(op==OP_BUY)
    {
      buy=0;
    }
   else if(op==OP_SELL)
    {
      sell=0;
    }
 }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool EquityBasedClose(string comment)
 {
   if(EQ_Based==false){return false;}
   double total=0.0;
   for(int i=0; i<OrdersTotal(); i++)
    {
      if(OrderSelect(i,SELECT_BY_POS)==true)
       {
         if(OrderSymbol()==Symbol() && OrderMagicNumber()==Magic_Number)
          {
            if(StringFind(OrderComment(),comment,0)!=-1)
             {
               total+=OrderProfit();
             }
          }
       }
    }
    if(total>=_profitTarget)
      {
         Print(total);
         Print("Closing All Orders. Reached Profit");CloseAllOrders();
      }
    if(total<=_stopLevel && useGridStop==true)
      {
         Print(total);
         Print("Closing All Orders. Reached Stop Level");CloseAllOrders();
      }
         //Print("Total[",total,"]");
   return false;
 }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool LegBasedClose(string comment)
 {
   if(LG_Based==false){return false;}
   for(int i=0; i<OrdersTotal(); i++)
     {
      if(OrderSelect(i,SELECT_BY_POS)==true)
       {
         if(OrderSymbol()==Symbol() && OrderMagicNumber()==Magic_Number)
           {
               if(StringFind(OrderComment(),comment,0)!=-1)
                {
                  if(OrderType()==OP_BUY)
                    {
                       if(OrderProfit()>=_profitTarget)
                          {
                           CloseAllOrders();
                          }
                        if(OrderProfit()<=_stopLevel && useGridStop==true)
                          {
                           CloseAllOrders();
                          }
                     }
                   else if(OrderType()==OP_SELL)
                     {
                        if(OrderProfit()>=_profitTarget)
                          {
                           CloseAllOrders();
                          }
                        if(OrderProfit()<=_stopLevel && useGridStop==true)
                          {
                           CloseAllOrders();
                          }
                     }
                  }
             }

         }
     }
     return false;
 }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CloseAllOrders()
{
   int total= OrdersTotal();
   for(int i=total-1;i>=0;i--)
    {
     if(OrderSelect(i,SELECT_BY_POS)==true)
      {
        if(OrderSymbol()==Symbol() && OrderMagicNumber()==Magic_Number)
         {
           if(StringFind(OrderComment(),Strat_Name1,0)!=-1)
            {
              if(OrderType()==OP_BUY)
               {
                 if(!OrderClose(OrderTicket(),OrderLots(),MarketInfo(OrderSymbol(),MODE_BID),Slippage,clrAntiqueWhite))
                    Print("Order Send Failed with Error[",GetLastError(),"]");
                        //continue;
               }
              if(OrderType()==OP_SELL)
               {
                  if(!OrderClose(OrderTicket(),OrderLots(),MarketInfo(OrderSymbol(),MODE_ASK),Slippage,clrAntiqueWhite))
                    Print("Order Send Failed with Error[",GetLastError(),"]");
                        //continue;
               }
            }
         }
      }
    }

   return false;
}
        
int getNewP_Order(int magic)
{
   int digit= (int)MarketInfo(Symbol(),MODE_DIGITS);
   int total = OrdersTotal();
   for(int i=total-1; i>=0;i--)
   {
      if(OrderSelect(i,SELECT_BY_POS)==true)
      {
         if(OrderMagicNumber()==magic && OrderSymbol()==Symbol())
         {
            if(OrderType()==OP_BUY || OrderType()== OP_SELL)
            {
               if(OrderStopLoss() == NormalizeDouble(0,digit))
                 {
                     return OrderTicket();
                 }                              
            }
         }
      }
   }
   return FAIL;
} 
bool PendingModify(int sl_type, double _slf, double _slv ,int tp_type, double _tpf, double _tpv)
{
   int digit= (int)MarketInfo(Symbol(),MODE_DIGITS);
   double point=MarketInfo(Symbol(),MODE_POINT);
   int op=FAIL;
   int ticket=0;
   double price=0.0;
   double atr=iATR(Symbol(),0,ATR_Period,0);
   double minsl=MarketInfo(Symbol(),MODE_STOPLEVEL);
   double min_sl=/*minsl*_point;*/
                 NormalizeDouble(minsl*point,Digits);
   double sl=0.0,tp=0.0;
   double mid=iBands(NULL,0,BB_Period,2,0,PRICE_CLOSE,MODE_MAIN,1);
   //Print("Minimum Broker SL: ",min_sl,"Point",point," Point",_Point);
   //double prev_sl, prev_tp;
   int total =OrdersTotal();
   for(int i=total-1; i>=0;i--)
   {
      if(OrderSelect(i,SELECT_BY_POS))
      {
         if(OrderMagicNumber() == p_Magic_Number && OrderSymbol() == Symbol())
         {
            if(OrderType() == OP_BUY || OrderType()==OP_SELL)
            {
               if(OrderStopLoss() == NormalizeDouble(0,digit))
               {
                 ticket =OrderTicket();
                 op=OrderType();
                 if(op == OP_BUY)
                  {
                     Print("Pending order Modify Method Accessing Buy");
                     if(Ticket_Check(OrderTicket())==true)
                       {
                        switch(sl_type)
                          {
                           case 0:
                              sl=Bid -(_slf*point);
                              Print("Stop Loss [",sl,"]");
                              break;
                           case 1:
                              sl=Bid -(atr*_slv);
                              Print("Stop Loss [",sl,"]");
                              break;
                           default :
                              Print("Error in SL Type. [",sl_type,"]");
                              break;
                          }
                        switch(tp_type)
                          {
                           case 0:
                              tp=Ask+(_tpf*point);
                              Print("Case 0 fix: Tp[",tp,"]");
                              break;
                           case 1:
                              tp=Ask+(atr*_tpv);
                              Print("Case 1 atr: Tp[",tp,"]");
                              break;
                           case 2:
                  
                              Print("Mid Band: ",mid);
                              tp=mid;
                              Print("Case 3: mid Tp[",tp,"]");
                              break;
                           default :
                              Print("Error in Tp Type. [",tp_type,"]");
                              break;
                          }
                        }
                     if(Bid-sl>=min_sl)
                      {
                        sl=NormalizeDouble(sl,digit);
                        Print("Stop Loss [",sl,"]");
                        if(Set_Order_Limit(Blue,ticket, sl,tp)){return true;}
                      }
                     if(Bid-sl<min_sl)
                      {
                        double toAdd=min_sl+(55*point);
                        sl=Bid-toAdd;
                        sl=NormalizeDouble(sl,digit);
                        Print("Stop Loss [",sl,"]");
                        if(Set_Order_Limit(Blue,ticket,sl,tp)){  return true; }      
                      }
                   }
                  else if(op == OP_SELL)
                  {
                     Print("Pending order Modify Method Accessing Sell");
                     if(Ticket_Check(OrderTicket())==true)
                      {
                         switch(sl_type)
                          {
                           case 0:
                              sl=Bid+(_slf*point);
                              Print("Stop Loss [",sl,"]");
                              break;
                           case 1:
                              sl=Bid+(atr*_slv);
                              Print("Stop Loss [",sl,"]");
                              break;
                          }
                        switch(tp_type)
                          {
                           case 0:
                              tp=Bid -(_tpf*point);
                              Print("Case 0: fix Tp[",tp,"]");
                              break;
                           case 1:
                              tp=Bid -(atr*_tpv);
                              Print("Case 1: atr Tp[",tp,"]");
                              break;
                           case 2:
                              tp=mid;
                              Print("Case 1: mid Tp[",tp,"]");
                              break;
                          }   
                       }
                      if(sl-Ask>=minsl && tp)
                       {
                        sl=NormalizeDouble(sl,digit);
                        Print("Stop Loss [",sl,"]");
                        if(Set_Order_Limit(Blue,ticket, sl,tp))return true;
                       }
                      if(sl-Ask<minsl)
                       {
                        double toAdd=min_sl+(7.0 *point);
                        sl=Ask+toAdd;
                        sl=NormalizeDouble(sl,digit);
                        Print("Stop Loss [",sl,"]");
                        if(Set_Order_Limit(Blue,ticket,sl,tp)){return true;}
                       }                    
                    }                  
               }
            }
         }
      }   
   }
   return false;
}    
bool _p_OrderModify(int ticket, int sl_type, double _slf, double _slv ,int tp_type, double _tpf, double _tpv)
{
   int digit= (int)MarketInfo(Symbol(),MODE_DIGITS);
   double point=MarketInfo(Symbol(),MODE_POINT);
   int op=FAIL;
   double price=0.0;
   double atr=iATR(Symbol(),0,ATR_Period,0);
   double minsl=MarketInfo(Symbol(),MODE_STOPLEVEL);
   double min_sl=/*minsl*_point;*/
                 NormalizeDouble(minsl*point,Digits);
   double sl=0.0,tp=0.0;
   double mid=iBands(NULL,0,BB_Period,2,0,PRICE_CLOSE,MODE_MAIN,1);
   //Print("Minimum Broker SL: ",min_sl,"Point",point," Point",_Point);
   double prev_sl, prev_tp;
   
   if(OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
   {
      op= OrderType();
      price =OrderOpenPrice();
      prev_sl =OrderStopLoss();
      prev_tp = OrderTakeProfit();
   }
   if(op == OP_BUY)
   {
      Print("Pending order Modify Method Accessing Buy");
      if(Ticket_Check(ticket)==true)
     {
      switch(sl_type)
        {
         case 0:
            sl=Bid -(_slf*point);
            Print("Stop Loss [",sl,"]");
            break;
         case 1:
            sl=Bid -(atr*_slv);
            Print("Stop Loss [",sl,"]");
            break;
         default :
            Print("Error in SL Type. [",sl_type,"]");
            break;
        }
      switch(tp_type)
        {
         case 0:
            tp=Ask+(_tpf*point);
            Print("Case 0 fix: Tp[",tp,"]");
            break;
         case 1:
            tp=Ask+(atr*_tpv);
            Print("Case 1 atr: Tp[",tp,"]");
            break;
         case 2:

            Print("Mid Band: ",mid);
            tp=mid;
            Print("Case 3: mid Tp[",tp,"]");
            break;
         default :
            Print("Error in Tp Type. [",tp_type,"]");
            break;
        }
      }
       if(Bid-sl>=min_sl)
        {
         sl=NormalizeDouble(sl,digit);
         Print("Stop Loss [",sl,"]");
         if(Set_Order_Limit(Blue,ticket, sl,tp)){return true;}
        }
      if(Bid-sl<min_sl)
        {
         double toAdd=min_sl+(55*point);
         sl=Bid-toAdd;
         sl=NormalizeDouble(sl,digit);
         Print("Stop Loss [",sl,"]");
         if(Set_Order_Limit(Blue,ticket,sl,tp)){  return true; }      
        }
    }
   else if(op == OP_SELL)
   {
      Print("Pending order Modify Method Accessing Sell");
      if(Ticket_Check(ticket)==true)
     {
       switch(sl_type)
        {
         case 0:
            sl=Bid+(_slf*point);
            Print("Stop Loss [",sl,"]");
            break;
         case 1:
            sl=Bid+(atr*_slv);
            Print("Stop Loss [",sl,"]");
            break;
        }
      switch(tp_type)
        {
         case 0:
            tp=Bid -(_tpf*point);
            Print("Case 0: fix Tp[",tp,"]");
            break;
         case 1:
            tp=Bid -(atr*_tpv);
            Print("Case 1: atr Tp[",tp,"]");
            break;
         case 2:
            tp=mid;
            Print("Case 1: mid Tp[",tp,"]");
            break;
        }   
     }
      if(sl-Ask>=minsl && tp)
        {
         sl=NormalizeDouble(sl,digit);
         Print("Stop Loss [",sl,"]");
         if(Set_Order_Limit(Blue,ticket, sl,tp))return true;
        }
      if(sl-Ask<minsl)
        {
         double toAdd=min_sl+(7.0 *point);
         sl=Ask+toAdd;
         sl=NormalizeDouble(sl,digit);
         Print("Stop Loss [",sl,"]");
         if(Set_Order_Limit(Blue,ticket,sl,tp)){return true;}
        }
     
   }
   return false;
}   

bool Check_Pending_Market()
{
   int total=OrdersTotal(),_total=OrdersHistoryTotal();
   int tick=0;
   if(total==0 )
   {
      return false;
   }
   for(int i=total-1; i>=0;i--)
   {
      if(OrderSelect(i,SELECT_BY_POS))
      {
         if(OrderMagicNumber() == p_Magic_Number && OrderSymbol() == Symbol())
         {
            if(OrderType()== OP_BUYSTOP || OrderType()==OP_SELLSTOP)
            {               
               datetime time= OrderOpenTime();
               tick=OrderTicket();
               if(isTime(time))
               {
                  Print("Deleting Pending Order");
                  if(!OrderDelete(tick,clrBurlyWood))
                  {
                     Print("Error Deleting Order. Error Code[",GetLastError(),"]");
                  }                  //Delete Order
               }
            }
            return false;
         }
      }
   }
  
   return false;
}
bool isTime(datetime time)
{
   int _total= OrdersHistoryTotal();
   for(int i=_total-1;i>=0;i--)
   {
      if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY))
      {
         if(OrderMagicNumber() == Magic_Number && OrderSymbol() == Symbol())
         {
            //if(OrderProfit()>0)
            //{
               if(OrderOpenTime()==time)
               {
                  return true;               //Order Delete
               }
            //}        
         }
      }   
   }
   return false;
}

double CalculateAvgHigh()
{
   double avg=0.0;
   double point =MarketInfo(Symbol(),MODE_POINT);
   int    digit =(int)MarketInfo(Symbol(),MODE_DIGITS);
   for(int i=1;i<=ADR_Period;i++)
   {
     avg+= iHigh(NULL,PERIOD_D1,i);
   }
   double highADR= NormalizeDouble(avg/ADR_Period,digit);
   return highADR;
}

double CalculateAvgLow()
{
   double avg=0.0;
   double point =MarketInfo(Symbol(),MODE_POINT);
   int    digit =(int)MarketInfo(Symbol(),MODE_DIGITS);
   for(int i=1;i<=ADR_Period;i++)
   {
     avg+= iLow(NULL,PERIOD_D1,i);
   }
   
   double lowADR= NormalizeDouble( avg/ADR_Period,digit);
   
   return lowADR;
}
void DisplayADR()
{
   double point =MarketInfo(Symbol(),MODE_POINT);
   int    digit =(int)MarketInfo(Symbol(),MODE_DIGITS);
   double avgHigh=CalculateAvgHigh();
   double avgLow=CalculateAvgLow();   
   double currHigh=NormalizeDouble(iHigh(NULL,PERIOD_D1,0),digit);
   double currLow=NormalizeDouble(iLow(NULL,PERIOD_D1,0),digit);
   double toAvgHigh=NormalizeDouble((avgHigh-currHigh)/Point,0);
   double toAvgLow=NormalizeDouble((currLow-avgLow)/Point,0);
   Comment("Average High ADR: [",avgHigh,"]\nCurrent Day High[",currHigh,"]\nPoints to ADR High[",toAvgHigh,"]\nAverage Low ADR: [",avgLow,"]\nCurrent Day Low[",currLow,"]\nPoints to ADR Low[",toAvgLow,"]\n");
}
double ConvertToPips(double value)
{
   if(Digits == 2 || Digits ==4)value =value;
   else value = 10 * value;
   return value;
}
double LotMoneyManagement()
{
   double stop= CalculateStop();
   double lot=0.0;
   double Risk=risk/100;
   lot = Risk * AccountEquity()/ MarketInfo(Symbol(),MODE_TICKVALUE)/stop;
   return lot;
}
double CalculateStop()
{
   double atr=iATR(Symbol(),0,ATR_Period,0);
   if(SL_Type1 == VOLATILITY)return atr * SL_Volatility_Factor1;
   else if(SL_Type1 == FIXED)return SL_Fixed1;
   return 0.0;
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
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Increase_Count(int  &a)
{
   a++;
}

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
      int OnInit()
        {
         //---
         _point=MyPoint();
         //---
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
   DisplayADR();

   
         //---
        
         Check_Market();
         Check_Pending_Market();
         if(order1Open)
           {
            int tick=getNewP_Order(p_Magic_Number);
            //Print("Ticket Number: ",tick);
           if(!(tick==FAIL))
            {
               Print("Pending Order is Opened");
             _p_OrderModify(tick,SL_Type2,SL_Fixed2,SL_Volatility_Factor2,
                               TP_Type2,TP_Fixed2,TP_Volatility_Factor2);
            }
        
           // int tick=getNewP_Order(p_Magic_Number);
            Check_Pending_Market();
           
            LegBasedClose(Strat_Name1);
            EquityBasedClose(Strat_Name1);
            Trailing_Stop_Revised(_trail1,Strat_Name1,_trailPoint1);
            JumpToBreakeven(_breakEven1,Strat_Name1,_whenJump1,_jumpBy1);
             if(entry_type== ADR && useGridding ==true)
                {
                   bool checkBuy=OrderIgnoreCheck(OP_BUY,Strat_Name1,buy_counter);
                   bool checkSell=OrderIgnoreCheck(OP_SELL,Strat_Name1,sell_counter);
                   if(Pattern_Point()==BUY && checkSell==false && buy_counter<numberOfLegs)
                    {
                     Print("Buy Counter [",buy_counter);
                     double newLot=prevLotBuy*increaseLLotBy;
                     Buy_Order(newLot,Strat_Name1,SL_Type1,SL_Fixed1,SL_Volatility_Factor1,
                               TP_Type1,TP_Fixed1,TP_Volatility_Factor1,OP_BUY);
                     prevLotBuy=newLot;
                     Increase_Count(buy_counter);
                    }
                  else if(Pattern_Point()==SELL && checkBuy==false && sell_counter<numberOfLegs)
                    {
                     Print("Sell Counter [",sell_counter);
                     double newLot=prevLotSell*increaseLLotBy;
                     Sell_Order(newLot,Strat_Name1,SL_Type1,SL_Fixed1,SL_Volatility_Factor1,
                                TP_Type1,TP_Fixed1,TP_Volatility_Factor1,OP_SELL);
                     prevLotSell=newLot;
                     Increase_Count(sell_counter);
                    }
                
                }
            if(IsNewBar())
              {
               bool checkBuy=OrderIgnoreCheck(OP_BUY,Strat_Name1,buy_counter);
               bool checkSell=OrderIgnoreCheck(OP_SELL,Strat_Name1,sell_counter);
               if(entry_type == BREAK && useGridding ==true)
               {
                  if(Pattern1()==BUY && checkSell==false && buy_counter<numberOfLegs)
                    {
                     Print("Buy Counter [",buy_counter);
                     double newLot=prevLotBuy*increaseLLotBy;
                     Buy_Order(newLot,Strat_Name1,SL_Type1,SL_Fixed1,SL_Volatility_Factor1,
                               TP_Type1,TP_Fixed1,TP_Volatility_Factor1,OP_BUY);
                     prevLotBuy=newLot;
                     Increase_Count(buy_counter);
                    }
                  else if(Pattern1()==SELL && checkBuy==false && sell_counter<numberOfLegs)
                    {
                     Print("Sell Counter [",sell_counter);
                     double newLot=prevLotSell*increaseLLotBy;
                     Sell_Order(newLot,Strat_Name1,SL_Type1,SL_Fixed1,SL_Volatility_Factor1,
                                TP_Type1,TP_Fixed1,TP_Volatility_Factor1,OP_SELL);
                     prevLotSell=newLot;
                     Increase_Count(sell_counter);
                    }
                }
                
                else if(entry_type == INVERSE && useGridding ==true)
                {
                   if(Pattern_Reverse()==BUY && checkSell==false && buy_counter<numberOfLegs)
                    {
                     Print("Buy Counter [",buy_counter);
                     double newLot=CalculateLot();
                     Buy_Order(newLot,Strat_Name1,SL_Type1,SL_Fixed1,SL_Volatility_Factor1,
                               TP_Type1,TP_Fixed1,TP_Volatility_Factor1,OP_BUY);
                     prevLotBuy=newLot;
                     Increase_Count(buy_counter);
                    }
                  else if(Pattern_Reverse()==SELL && checkBuy==false && sell_counter<numberOfLegs)
                    {
                     Print("Sell Counter [",sell_counter);
                     double newLot=CalculateLot();
                     Sell_Order(newLot,Strat_Name1,SL_Type1,SL_Fixed1,SL_Volatility_Factor1,
                                TP_Type1,TP_Fixed1,TP_Volatility_Factor1,OP_SELL);
                     prevLotSell=newLot;
                     Increase_Count(sell_counter);
                    }
                }
              
              }
           }
         if(IsNewBar())
           {

            if(useStrategy1)
              {
               
               Order_Ignore(Strat_Name1,_timegap1,buyIgnore1,OP_BUY);
               Order_Ignore(Strat_Name1,_timegap1,sellIgnore1,OP_SELL);
               bool checkBuy=OrderIgnoreCheck(OP_BUY,Strat_Name1,buy_counter);
               bool checkSell=OrderIgnoreCheck(OP_SELL,Strat_Name1,sell_counter);
               
               if(entry_type == BREAK)
               { 
                  if(Pattern1()==BUY && checkSell==false)
                    {
                     Buy_Order(startLot,Strat_Name1,SL_Type1,SL_Fixed1,SL_Volatility_Factor1,
                               TP_Type1,TP_Fixed1,TP_Volatility_Factor1,OP_BUY);
                     prevLotBuy=startLot;
                     sell_counter=0;
                     Increase_Count(buy_counter);
                    }
                  else if(Pattern1()==SELL && checkBuy==false)
                    {
                     Sell_Order(startLot,Strat_Name1,SL_Type1,SL_Fixed1,SL_Volatility_Factor1,
                                TP_Type1,TP_Fixed1,TP_Volatility_Factor1,OP_SELL);
                     prevLotSell= startLot;
                     buy_counter=0;
                     Increase_Count(sell_counter);
                    }
               }
              
               else if(entry_type == INVERSE)
               {
                  if(Pattern_Reverse()==BUY && checkSell==false)
                    {
                     Buy_Order(startLot,Strat_Name1,SL_Type1,SL_Fixed1,SL_Volatility_Factor1,
                               TP_Type1,TP_Fixed1,TP_Volatility_Factor1,OP_BUY);
                     prevLotBuy=startLot;
                     sell_counter=0;
                     Increase_Count(buy_counter);
                    }
                  else if(Pattern_Reverse()==SELL && checkBuy==false)
                    {
                     Sell_Order(startLot,Strat_Name1,SL_Type1,SL_Fixed1,SL_Volatility_Factor1,
                                TP_Type1,TP_Fixed1,TP_Volatility_Factor1,OP_SELL);
                     prevLotSell= startLot;
                     buy_counter=0;
                     Increase_Count(sell_counter);
                    }
               }
                if(entry_type == ADR)
                 {
                  if(Pattern_ADR()==BUY && checkSell ==false)
                  {
                      Buy_Order(startLot,Strat_Name1,SL_Type1,SL_Fixed1,SL_Volatility_Factor1,
                                TP_Type1,TP_Fixed1,TP_Volatility_Factor1,OP_BUY);
                      prevLotBuy= startLot;          
                      Increase_Count(buy_counter);                        
                                    
                  }
                  else if(Pattern_ADR()==SELL && checkBuy == false)
                  {
                     Sell_Order(startLot,Strat_Name1,SL_Type1,SL_Fixed1,SL_Volatility_Factor1,
                                TP_Type1,TP_Fixed1,TP_Volatility_Factor1,OP_SELL);
                     prevLotSell= startLot;
                     Increase_Count(sell_counter);
                  }
                }
              }
           }
               
        }
//+------------------------------------------------------------------+
