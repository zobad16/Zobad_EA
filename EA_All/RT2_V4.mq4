//|                               Awais Tariq, Mobile: +923227750059 |
//|                            https://www.facebook.com/awaistariq89 |
//+------------------------------------------------------------------+
#property copyright "Awais Tariq, Mobile: +923227750059"
#property link      "https://www.facebook.com/awaistariq89"
#property description ""
#property strict
// define
#define timer D'2026.08.20 00:00:00'
//+------------------------------------------------------------------+
#define nd NormalizeDouble
#define d  Digits()
//+------------------------------------------------------------------+
enum be {
FIXED_BREAKEVEN,
JUMP_BREAKEVEN
};
//+------------------------------------------------------------------+
// global variables for parameters

enum n {ms = 1/*start*/,mc = 0/*stop*/};
enum n1 {m1 = 1/*atr*/ /*,m2 = 2/*% from balance*/,m3 = 3/*fix*/,};

// // order
extern string Set0="-------Old Setting--------";
extern double lot      = 1; // lot
extern n1     tpv      = 1;   // take-profit
extern double tp       = 3.0; // take-profit
extern n      tpv1     = 1;   // take-profit % from balance
extern double tp1      = 3.0; // take-profit % from balance
extern double sl       = 1.5; // stop-loss
extern int    slippage = 0; // проскальзывание
extern int    mg       = 1; // magic number
extern string comment  = "robot RT" ; // comment
//+------------------------------------------------------+
extern string Set1="-------NewRules--------";
extern bool   NewRule=false;
extern int    StopLoss=0;
extern int    TakeProfit=0;
extern string Set2="-------Trailing stop Setting-------";
extern bool   TrailingStopEnable=true;
extern int    TrailStep=10;
extern string Set6="-----Break Even----";
extern bool UseBreakEven=true;
extern be BreakEvenType=JUMP_BREAKEVEN;
extern int BreakEvenPips=13;
extern string Set5="-----Money Managment----";
extern bool   MoneyManagmentEnable=true;
extern n      risk     = 0; // risk
extern double riskz    = 2; // risk in %
//+-------------------------------------+
int      MaxSlippage=5;
int      Trend=2;
datetime LastTime;
// // other
double point;
int digits,Q;
// global variables for parameters from indicators
extern string Set3="-------Bolinger Band Setting-------";
extern ENUM_TIMEFRAMES    bb_tf        = PERIOD_H4;   // bolinger::time-fream
extern int                bb_period    = 20;          // bolinger::period 
extern double             bb_deviation = 2;           // bolinger::deviation
       int                bb_shift     = 0;           // bolinger::shift
extern ENUM_APPLIED_PRICE bb_price     = PRICE_CLOSE; // bolinger::price

extern ENUM_TIMEFRAMES    atr_tf       = PERIOD_H4;   // atr::time-fream
extern int                atr_period   = 20;          // atr::period

// global variables
//+------------------------------------------------------------------+
datetime ExpireTime=D'2026.10.30 10:30';
string   ProviderEmail="forexservicesinpakistan@gmail.com";
//+------------------------------------------------------------------+

// global variables for indicators



// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

int OnInit()
  {

  if(timer<TimeCurrent()) return(INIT_FAILED);
  //================
   if(Digits<4)
     {
      point=0.01;
      digits=2;
     }
   else
     {
      point=0.0001;
      digits=4;
     }
  //================
  return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
  }
//+---------------------------------+
void OnTick()
  {
      if(TimeCurrent()<ExpireTime)
       {
           f();
           if(LastTime!=Time[1])
            {
              LastTime=Time[1];
              Trend=2;
              NewRuleFun();
              GetOrder();       
            }
           if(TrailingStopEnable==true)
            TrailingStop();
           if(UseBreakEven==true)
            sub_trailing();  
        }
      else
       {
            Comment("EA Expired , please contact to "+ProviderEmail);
       }
  }
//+---------------------------------+
int NewRuleFun()
  {
//---
      double HBB=iBands(Symbol(),PERIOD_CURRENT,bb_period,bb_deviation,bb_shift,bb_price,1,1);
      double LBB=iBands(Symbol(),PERIOD_CURRENT,bb_period,bb_deviation,bb_shift,bb_price,2,1);
      if(NewRule==false)
       return(0);
      if(Open[1]>HBB && Close[1]<HBB && Close[1]>LBB && TotalOrder(0)==0)
       Trend=1;
      if(Open[1]<LBB && Close[1]>LBB && Close[1]<HBB && TotalOrder(1)==0)
       Trend=0;
//---
      return(0);
  }
//+---------------------------------+
void f()
  {

  if(timer<TimeCurrent()) return;

  static int ao = 0; // authorization order

  static int aab1 = Bid>=iBands(Symbol(),bb_tf,bb_period,bb_deviation,bb_shift,bb_price,MODE_UPPER,1)?0:1;
  static int aas1 = Bid<=iBands(Symbol(),bb_tf,bb_period,bb_deviation,bb_shift,bb_price,MODE_LOWER,1)?0:1;

  static int aab2 = 1;
  static int aas2 = 1;

  static int tb = 0;
  static int ts = 0;

  double bb_up  = iBands(Symbol(),bb_tf,bb_period,bb_deviation,bb_shift,bb_price,MODE_UPPER,1);
  double bb_dwn = iBands(Symbol(),bb_tf,bb_period,bb_deviation,bb_shift,bb_price,MODE_LOWER,1);

  if(aas1 && aas2 && Bid>bb_up)
   {
   aas1 = 0;
   ao = 2;
   aab2 = 1;
   aas2 = 0;
   }
  else aas1 = 1;

  if(aab1 && aab2 && Bid<=bb_dwn)
   {
   aab1 = 0;
   ao = 1;
   aas2 = 1;
   aab2 = 0;
   }
  else aab1= 1;

  // // // // // // // // // // // // // //

  int t=0;

  if(NewRule==false)
   if(ao==1 && order_start_b(t))
    {
     tb=t;
     ao=0;
    }

  if(NewRule==false)
   if(ao==2 && order_start_s(t))
    {
     ts=t;
     ao=0;
    }

  // // // // // // // // // // // // // //

  if(tb && OrderSelect(tb,SELECT_BY_TICKET))
   {
   if(OrderCloseTime())
    {

    if(OrderComment()==comment+"[tp]") aab2 = 1;

    tb = 0;

    }
   }

  if(ts && OrderSelect(ts,SELECT_BY_TICKET))
   {
   if(OrderCloseTime())
    {

    if(OrderComment()==comment+"[tp]") aas2 = 1;

    ts = 0;

    }
   }

  // // // // // // // // // // // // // //

  static int td[100];

  for(int c = OrdersTotal()-1 ; c>=0 ; c--)
   {
   if(OrderSelect(c,SELECT_BY_POS,MODE_TRADES))
    {
    if(OrderSymbol()==Symbol() && OrderMagicNumber()==mg && OrderComment()==comment)
     {
     if(OrderProfit()>AccountBalance()/100*tp1)
      {
      Print("order #"+IntegerToString(OrderTicket())+" close due to profit in %");
      for(int c1 = 0; c1<100; c1++)
       {
       if(!td[c1])
        {
        td[c1]=OrderTicket();
        break;
        }
       }
      }
     }
    }
   }

  for(int c = 0; c<100; c++)
   {
   if(td[c] && OrderSelect(td[c],SELECT_BY_TICKET))
    {
    if(OrderType()==OP_BUY)
     {
     if(OrderClose(OrderTicket(),OrderLots(),MarketInfo(OrderSymbol(),MODE_BID),0,clrYellow))
      {
      e_ts_vi1[3]=0;
      e_ts_vi2[3]=0;
      td[c]=0;
      }
     else
      {
      if(e_ts(GetLastError(),3)) td[c]=0;
      }
     }
    else
    if(OrderType()==OP_SELL)
     {
     if(OrderClose(OrderTicket(),OrderLots(),MarketInfo(OrderSymbol(),MODE_ASK),0,clrYellow))
      {
      e_ts_vi1[3]=0;
      e_ts_vi2[3]=0;
      td[c]=0;
      }
     else
      {
      if(e_ts(GetLastError(),3)) td[c]=0;
      }
     }
    }
   }

  // // // // // // // // // // // // // //

  }

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

int order_start_b(int &ticket)
 {

 double price=MarketInfo(Symbol(),MODE_ASK);

 double atr = iATR(Symbol(),atr_tf,atr_period,0);

 double slz  = 0;

 if(nd(sl,2)) slz = price-atr*sl;

 double lotz = lot;

 if(risk)
  {
  lotz = AccountBalance()/100*riskz;
  lotz = lotz/(nd((MathMax(price,slz)-MathMin(price,slz))/Point(),d))/10;
  }

 int dl = MarketInfo(Symbol(),MODE_LOTSTEP)<=0.01 ? 2 :  MarketInfo(Symbol(),MODE_LOTSTEP)<=0.1 ? 1 : 
          MarketInfo(Symbol(),MODE_LOTSTEP)<=1? 0 : MarketInfo(Symbol(),MODE_LOTSTEP)<=10 ? -1 : -2;

 lotz = nd(lotz,dl);

 lotz = NormalizeDouble(MathMax(MathMin(lotz,MarketInfo(Symbol(),MODE_MAXLOT)),MarketInfo(Symbol(),MODE_MINLOT)),2);

 double tpz  = 0;

 if(nd(tp,2))
  {
  if(tpv==1)
  tpz = price+atr*tp;
  else
  if(tpv==2)
   {
   double z = nd(AccountBalance()/100*tp/(MarketInfo(Symbol(),MODE_TICKSIZE)*lotz),d);
   tpz = price+z*Point();
   }
  else tpz = price+tp*Point();
  }
  int t=OrderSend(Symbol(),OP_BUY,lotz,price,slippage,slz,tpz,comment,mg);

 if(t>0)
  {
  ticket=t;
  e_ts_vi1[1]=0;
  e_ts_vi2[1]=0;
  return 1;
  }
 else
  {
  e_ts(GetLastError(),1);
  return 0;
  }
 }

int order_start_s(int &ticket)
 {

 double price=MarketInfo(Symbol(),MODE_BID);

 double atr = iATR(Symbol(),atr_tf,atr_period,0);

 double slz  = 0;

 if(nd(sl,d)) slz = price+atr*sl;

 double lotz = lot;

 if(risk)
  {
  lotz = AccountBalance()/100*riskz;
  lotz = lotz/(nd((MathMax(price,slz)-MathMin(price,slz))/Point(),d))/10;
  }

 int dl = MarketInfo(Symbol(),MODE_LOTSTEP)<=0.01 ? 2 :  MarketInfo(Symbol(),MODE_LOTSTEP)<=0.1 ? 1 : 
          MarketInfo(Symbol(),MODE_LOTSTEP)<=1? 0 : MarketInfo(Symbol(),MODE_LOTSTEP)<=10 ? -1 : -2;

 lotz = nd(lotz,dl);

 lotz = NormalizeDouble(MathMax(MathMin(lotz,MarketInfo(Symbol(),MODE_MAXLOT)),MarketInfo(Symbol(),MODE_MINLOT)),2);

 double tpz  = 0;

 if(nd(tp,d))
  {
  if(tpv==1)
  tpz = price-atr*tp;
  else
  if(tpv==2)
   {
   double z = nd(AccountBalance()/100*tp/(MarketInfo(Symbol(),MODE_TICKSIZE)*lotz),d);
   tpz = price-z*Point();
   }
  else tpz = price-tp*Point();
  }
  
  int t=OrderSend(Symbol(),OP_SELL,lotz,price,slippage,slz,tpz,comment,mg);

 if(t>0)
  {
  ticket=t;
  e_ts_vi1[1]=0;
  e_ts_vi2[1]=0;
  return 1;
  }
 else
  {
  e_ts(GetLastError(),1);
  return 0;
  }
 }

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

int closef(int zaclose)
 {

 int r = 1;

 for(int c = OrdersTotal()-1 ; c>=0 ; c--)
  {
  if(OrderSelect(c,SELECT_BY_POS,MODE_TRADES))
   {
   if(OrderMagicNumber()==mg && OrderSymbol()==Symbol())
    {
    if(zaclose==1 && OrderType()==OP_BUY)
     {
     if(OrderClose(OrderTicket(),OrderLots(),MarketInfo(OrderSymbol(),MODE_BID),0,clrYellow))
      {
      e_ts_vi1[3]=0;
      e_ts_vi2[3]=0;
      }
     else
      {
      r = 0;
      e_ts(GetLastError(),3);
      }
     }
    else
    if(zaclose==2 && OrderType()==OP_SELL)
     {
     if(OrderClose(OrderTicket(),OrderLots(),MarketInfo(OrderSymbol(),MODE_ASK),0,clrYellow))
      {
      e_ts_vi1[3]=0;
      e_ts_vi2[3]=0;
      }
     else
      {
      r = 0;
      e_ts(GetLastError(),3);
      }
     }
    }
   }
  }

 return r;

 }

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

string gs_f(string s, int index1, int index2)
 {

 string r = "";

 int z_index2 = index2 ? MathMin(index1+index2-1,StringLen(s)-1) : StringLen(s)-1;

 for(int c = index1; c<=z_index2 ; c++) r += ShortToString(StringGetChar(s,c));

 return r;

 }

////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////

// errors from the trading server

// если ошибка поторяется менее 10 раз подрят, без успещного исполнения
// возвратит значение false
// в print напишит код ошибки
// если ошибка поторяется 10 или более раз подрят, без успещного исполнения
// возвратит значение true
// в alert напишит код ошибки

string e_ts_vs;
string e_ts_vs2[5]={"", "the order is not open due to:\n",
                        "the order is not modified due to:\n",
                        "the order is not closed due to:\n",
                        "the order is not delete due to:\n"};
int    e_ts_vi=false;
int    e_ts_vi1[5]={0,0,0,0,0};
int    e_ts_vi2[5]={0,0,0,0,0};
int    e_ts_sum=50;

bool e_ts( int getlasterror_z,int z)
 {

 e_ts_vs = IntegerToString(getlasterror_z);
 e_ts_vi = false;

// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

 if(e_ts_vi1[z]==getlasterror_z) // // //
  {
  e_ts_vi2[z]++;
  if(e_ts_vi2[z]>=e_ts_sum)
   {
   e_ts_vi=true;
   }
  }
 else
  {
  e_ts_vi2[z]=0;
  }
 e_ts_vi1[z]=getlasterror_z;

// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

 e_ts_vs= e_ts_vs2[z]+e_ts_vs; // // //

 if(e_ts_vi) // // //
  {
  Alert(e_ts_vs);
  }
 else
  {
  Print(e_ts_vs);
  }

 return e_ts_vi;

 }
//+--------------------------------------+
//+------------------------------------------------------------------+
int TotalOrder(int T)
  {
      int C=0;
      for(int i=0; i<=OrdersTotal(); i++)
       if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true)
        if(OrderType()==T && OrderMagicNumber()==mg && OrderSymbol()==Symbol())
         C++;
      return(C);
  }
//+------------------------------------------------------------------+
void GetOrder()
  {
      double SL=0;
      double TP=0;
      double slz=0;
      double atr=0;
      double lotz=0;
      int    Ticket=0;
      if(Trend==0 && TotalOrder(0)==0)
       {         
         atr = iATR(Symbol(),atr_tf,atr_period,0);
         if(nd(sl,2)) 
          SL = Ask-atr*sl;
         //========================
         lotz=CalcLot(Ask,SL);
         //========================
          if(nd(tp,2))
           {
              if(tpv==1)
              TP = Ask+atr*tp;
              else
              if(tpv==2)
               {
               double z = nd(AccountBalance()/100*tp/(MarketInfo(Symbol(),MODE_TICKSIZE)*lotz),d);
               TP = Ask+z*Point();
               }
              else TP = Ask+tp*Point();
           }
         //========================
         Ticket=OrderSend(Symbol(),0,lotz,Ask,MaxSlippage,SL,TP,"RT2",mg,0,clrBlue);       
       }
      if(Trend==1 && TotalOrder(1)==0)
       {
         atr = iATR(Symbol(),atr_tf,atr_period,0);
         if(nd(sl,2)) 
          SL = Bid+atr*sl;
         //========================
          lotz=CalcLot(Bid,SL);
         //========================
          if(nd(tp,2))
           {
              if(tpv==1)
              TP = Bid-atr*tp;
              else
              if(tpv==2)
               {
               double z = nd(AccountBalance()/100*tp/(MarketInfo(Symbol(),MODE_TICKSIZE)*lotz),d);
               TP = Bid-z*Point();
               }
              else TP = Bid-tp*Point();
           }
         //========================
         Ticket=OrderSend(Symbol(),1,lotz,Bid,MaxSlippage,SL,TP,"RT2",mg,0,clrRed);       
       }
       
  }
//+------------------------------------------------------------------+
double CalcLot(double P, double S)
  {
//---
         if(MoneyManagmentEnable==true)
          return(MoneyManagementFunc(P,S));
         return(lot);
//---
  }
//+------------------------------------------------------------------+
void TrailingStop()
  {
      //---
         bool Check=false;
         for(int i=0; i<=OrdersTotal(); i++)
          if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true)
           {
               if(OrderType()==0 && OrderMagicNumber()==mg && OrderSymbol()==Symbol())
                if(PipProfit()>TrailStep && (StopDistance(0)>=2*TrailStep || OrderStopLoss()==0))
                 if((Bid-TrailStep*_Point)>OrderStopLoss() || OrderStopLoss()==0)
                  Check=OrderModify(OrderTicket(),OrderOpenPrice(),Bid-TrailStep*_Point,OrderTakeProfit(),OrderExpiration(),clrGold);
               //---
               if(OrderType()==1 && OrderMagicNumber()==mg && OrderSymbol()==Symbol())
                if(PipProfit()>TrailStep && (StopDistance(1)>=2*TrailStep || OrderStopLoss()==0))
                 if((Ask+TrailStep*_Point)<OrderStopLoss() || OrderStopLoss()==0)
                  Check=OrderModify(OrderTicket(),OrderOpenPrice(),Ask+TrailStep*_Point,OrderTakeProfit(),OrderExpiration(),clrGold);
           }
      //---
  }
//+------------------------------------------------------------------+
double PipProfit()
  {
      double R=OrderProfit()/OrderLots()/MarketInfo(OrderSymbol(),MODE_TICKVALUE);
      return(NormalizeDouble(R,0));
  }
//+------------------------------------------------------------------+
double StopDistance(int T)
  {
      double R=0;
      if(T==0)
       {
         R=(Bid-OrderStopLoss())*MathPow(10,_Digits);
       }
      //---
      if(T==1)
       {
         R=(OrderStopLoss()-Bid)*MathPow(10,_Digits);         
       }
      return(NormalizeDouble(R,0));
  }
//+------------------------------------------------------------------+
void sub_trailing() 
{
  for (int i=0; i<OrdersTotal(); i++) 
  {
    if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) 
    {
      if (OrderSymbol()==Symbol() && OrderMagicNumber()==mg ) 
      {
         if (OrderType()==OP_SELL) 
         {
            if (OrderOpenPrice()-Ask>BreakEvenPips*point && (OrderStopLoss() > OrderOpenPrice()|| OrderStopLoss()==0)) 
            {
                  ModifyStopLoss(OrderOpenPrice());
            }
            
            if (OrderStopLoss()-Ask>(BreakEvenPips*2)*point && OrderStopLoss() <= OrderOpenPrice()&&BreakEvenType==JUMP_BREAKEVEN) 
            {
                  ModifyStopLoss(Ask+BreakEvenPips*point);
            }
         }
         if (OrderType()==OP_BUY)
         {
            if (Bid-OrderOpenPrice()>BreakEvenPips*point && (OrderStopLoss() < OrderOpenPrice()|| OrderStopLoss()==0)) 
            {
                  ModifyStopLoss(OrderOpenPrice());
            }
            
            if (Bid-OrderStopLoss()>(BreakEvenPips*2)*point && OrderStopLoss() >= OrderOpenPrice()&&BreakEvenType==JUMP_BREAKEVEN) 
            {
                  ModifyStopLoss(Bid-BreakEvenPips*point);
            }
         }
      }
    }
  }
}
//+------------------------------------------------------------------+
void ModifyStopLoss(double ldStop) 
{
  bool   fm;
  double ldOpen=OrderOpenPrice();
  double ldTake=OrderTakeProfit();

  fm=OrderModify(OrderTicket(), ldOpen, ldStop, ldTake, 0, Pink);
}
//+------------------------------------------------------------------+
double MoneyManagementFunc(double price, double slz)
  {
//---
    double lotz=lot;
    if(risk)
     {
        lotz = AccountBalance()/100*riskz;
        lotz = lotz/(nd((MathMax(price,slz)-MathMin(price,slz))/Point(),d))/10;
     }
//---
   return(lotz);
  }
//+------------------------------------------------------------------+