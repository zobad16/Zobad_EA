//|                               Awais Tariq, Mobile: +923227750059 |
//|                            https://www.facebook.com/awaistariq89 |
//+------------------------------------------------------------------+
#property copyright "Awais Tariq, Mobile: +923227750059"
#property link      "https://www.facebook.com/awaistariq89"
#property description ""
#property strict
// define
#define timer D'2026.11.11 00:00:00'
//+------------------------------------------------------------------+
#define nd NormalizeDouble
#define d  Digits()
//+------------------------------------------------------------------+
enum be
  {
   FIXED_BREAKEVEN,
   JUMP_BREAKEVEN
  };
//+------------------------------------------------------------------+
// global variables for parameters

enum n {ms=1/*start*/,mc=0/*stop*/};
enum n1 {m1=1/*atr*/ /*,m2 = 2/*% from balance*/,m3=3/*fix*/,};

// // order
extern string Set0="-------Old Setting--------";
extern double lot=1; // lot
extern n1     tpv      = 1;   // take-profit
extern double tp       = 3.0; // take-profit
extern n      tpv1     = 1;   // take-profit % from balance
extern double tp1      = 3.0; // take-profit % from balance
extern double sl       = 1.5; // stop-loss

extern bool   UseATR2orders=true;
extern double lot2=1; // lot 2
extern n1     tpv2      = 1;   // take-profit 2 
extern double tp2       = 3.0; // take-profit 2
extern n      tpv12     = 1;   // take-profit % from balance 2
extern double tp12      = 3.0; // take-profit % from balance 2
extern double sl2=1.5; // stop-loss 2

extern int    slippage = 0; // ïðîñêàëüçûâàíèå
extern int    mg       = 1; // magic number
extern string comment="robot RT"; // comment
//+------------------------------------------------------+
extern string Set1="-------NewRules--------";
bool   NewRule=true;
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
extern n      risk2     = 0; // risk 2
extern double riskz2    = 2; // risk in % 2
extern bool   UseATRMinMAx=true;
extern double ATRMin=0.0001;
extern double ATRMax=0.0026;

extern bool   TrailingStopEnable2=true;
extern int    TrailStep2=10;
extern bool UseBreakEven2=true;
extern be BreakEvenType2=JUMP_BREAKEVEN;
extern int BreakEvenPips2=13;
extern string Set7="------SecondEntry_Setting----";
extern bool   SecondEntryRule=true;
extern bool   AtrFilter_SecondEntry=true;
//+-------------------------------------+
int      MaxSlippage=5;
int      Trend=2;
datetime LastTime;
string   Orders[2];
// // other
double point;
int digits,Q;
// global variables for parameters from indicators
extern string Set3="-------Bolinger Band Setting-------";
extern ENUM_TIMEFRAMES    bb_tf        = PERIOD_H4;   // bolinger::time-fream
extern int                bb_period    = 20;          // bolinger::period 
extern double             bb_deviation = 2;           // bolinger::deviation
int                bb_shift=0;           // bolinger::shift
extern ENUM_APPLIED_PRICE bb_price=PRICE_CLOSE; // bolinger::price

extern ENUM_TIMEFRAMES    atr_tf       = PERIOD_H4;   // atr::time-fream
extern int                atr_period   = 20;          // atr::period

                                                      // global variables
 int                ArrSize=3;
 int                distBuy=20;
color              ArrColorBuy=clrBlue;
 int                distSell=20;
 color              ArrColorSell=clrRed;

//+------------------------------------------------------------------+
datetime ExpireTime=D'2026.11.11 10:30';
datetime SecondBuyTime;
datetime SecondSellTime;
string   ProviderEmail="forexservicesinpakistan@gmail.com";
//+------------------------------------------------------------------+
datetime dt=0;
bool     SecondSell=false;
bool     SecondBuy=false;
double   HighBBand=0;
double   LowBBand=0;
// global variables for indicators

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

int OnInit()
  {

   if(!IsTesting())
     {
      Orders[0]="Order_1_"+Symbol()+"_"+IntegerToString(mg);
      Orders[1]="Order_2_"+Symbol()+"_"+IntegerToString(mg);
     }
   else
     {
      Orders[0]="Order_1_"+Symbol();
      Orders[1]="Order_2_"+Symbol();
     }

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
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   GlobalVariableDel(Orders[0]);
   GlobalVariableDel(Orders[1]);
  }
//+---------------------------------+
void OnTick()
  {
   if(UseATRMinMAx)
     {

      if(dt==Time[0])return;
      double _atr=NormalizeDouble(iATR(Symbol(),atr_tf,atr_period,0),Digits);
      if(TotalOrder(OP_BUY)+TotalOrder(OP_SELL)==0 && (_atr<ATRMin || _atr>ATRMax)){dt=Time[0];return;}
     }

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
      if(TrailingStopEnable==true && !UseATR2orders)
         TrailingStop(-1);
      if(TrailingStopEnable==true && UseATR2orders)
         TrailingStop((int)(GlobalVariableGet(Orders[0])));
      if(TrailingStopEnable2==true && UseATR2orders)
         TrailingStop2((int)(GlobalVariableGet(Orders[1])));
      if(UseBreakEven==true && !UseATR2orders)
         sub_trailing(-1);
      if(UseBreakEven==true && UseATR2orders)
         sub_trailing((int)(GlobalVariableGet(Orders[0])));
      if(UseBreakEven2==true && UseATR2orders)
         sub_trailing2((int)(GlobalVariableGet(Orders[1])));
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
   HighBBand=HBB;
   LowBBand=LBB;
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

   static int ao=0; // authorization order

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
      aas1=0;
      ao=2;
      aab2 = 1;
      aas2 = 0;
     }
   else aas1=1;

   if(aab1 && aab2 && Bid<=bb_dwn)
     {
      aab1=0;
      ao=1;
      aas2 = 1;
      aab2 = 0;
     }
   else aab1=1;

// // // // // // // // // // // // // //

   int t=0;




if(NumberOfPositions(Symbol(),-1)==0)
{
     if(NewRule==false)
      if(ao==1 && order_start_b(t))
        {
         if(
            ObjectFind(WindowExpertName()+IntegerToString(mg)+TimeToStr(Time[1]))<0
            )
           {
            ObjectCreate(0,WindowExpertName()+IntegerToString(mg)+TimeToStr(Time[1]),OBJ_ARROW_UP,0,Time[1],Low[1]-distBuy*Point);
            ObjectSetInteger(0,WindowExpertName()+IntegerToString(mg)+TimeToStr(Time[1]),OBJPROP_COLOR,ArrColorBuy);
            ObjectSet(WindowExpertName()+IntegerToString(mg)+TimeToStr(Time[1]),OBJPROP_WIDTH,ArrSize);
           }
            tb=t;
            ao=0;
        }


     if(NewRule==false)
      if(ao==2 && order_start_s(t))
        {
            if(
               ObjectFind(WindowExpertName()+IntegerToString(mg)+TimeToStr(Time[1]))<0
               )
              {
               ObjectCreate(0,WindowExpertName()+IntegerToString(mg)+TimeToStr(Time[1]),OBJ_ARROW_DOWN,0,Time[1],High[1]+distSell*Point);
               ObjectSetInteger(0,WindowExpertName()+IntegerToString(mg)+TimeToStr(Time[1]),OBJPROP_COLOR,ArrColorSell);
               ObjectSet(WindowExpertName()+IntegerToString(mg)+TimeToStr(Time[1]),OBJPROP_WIDTH,ArrSize);
              }
               ts=t;
               ao=0;
        }
}
// // // // // // // // // // // // // //

   if(tb && OrderSelect(tb,SELECT_BY_TICKET))
     {
      if(OrderCloseTime())
        {

         if(OrderComment()==comment+"[tp]") aab2=1;

         tb=0;

        }
     }

   if(ts && OrderSelect(ts,SELECT_BY_TICKET))
     {
      if(OrderCloseTime())
        {

         if(OrderComment()==comment+"[tp]") aas2=1;

         ts=0;

        }
     }

// // // // // // // // // // // // // //

   static int td[100];

   for(int c=OrdersTotal()-1; c>=0; c--)
     {
      if(OrderSelect(c,SELECT_BY_POS,MODE_TRADES))
        {
         if(OrderSymbol()==Symbol() && OrderMagicNumber()==mg && OrderComment()==comment)
           {
            if(OrderProfit()>AccountBalance()/100*tp1)
              {
               Print("order #"+IntegerToString(OrderTicket())+" close due to profit in %");
               for(int c1=0; c1<100; c1++)
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

   for(int c=0; c<100; c++)
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
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

int order_start_b(int &ticket)
  {

   double price=MarketInfo(Symbol(),MODE_ASK);

   double atr=iATR(Symbol(),atr_tf,atr_period,0);

   double slz=0;

   if(nd(sl,2)) slz=price-atr*sl;

   double lotz=lot;

   if(risk)
     {
      lotz = AccountBalance()/100*riskz;
      lotz = lotz/(nd((MathMax(price,slz)-MathMin(price,slz))/Point(),d))/10;
     }

   int dl=MarketInfo(Symbol(),MODE_LOTSTEP)<=0.01 ? 2 :  MarketInfo(Symbol(),MODE_LOTSTEP)<=0.1 ? 1 :
          MarketInfo(Symbol(),MODE_LOTSTEP)<=1? 0 : MarketInfo(Symbol(),MODE_LOTSTEP)<=10 ? -1 : -2;

   lotz=nd(lotz,dl);

   //lotz=NormalizeDouble(MathMax(MathMin(lotz,MarketInfo(Symbol(),MODE_MAXLOT)),MarketInfo(Symbol(),MODE_MINLOT)),2);
   if(lotz>MarketInfo(Symbol(),MODE_MAXLOT))
    lotz=MarketInfo(Symbol(),MODE_MAXLOT);
   if(lotz<MarketInfo(Symbol(),MODE_MINLOT))
    lotz=MarketInfo(Symbol(),MODE_MINLOT);

   double tpz=0;

   if(nd(tp,2))
     {
      if(tpv==1)
         tpz=price+atr*tp;
      else
      if(tpv==2)
        {
         double z=nd(AccountBalance()/100*tp/(MarketInfo(Symbol(),MODE_TICKSIZE)*lotz),d);
         tpz=price+z*Point();
        }
      else tpz=price+tp*Point();
     }

   if(!UseATR2orders)
     {
      int t=OrderSend(Symbol(),OP_BUY,lotz,price,slippage,slz,tpz,comment,mg);
      //         Print(t," Buy11 ",TimeToString(TimeCurrent(),TIME_MINUTES|TIME_SECONDS));
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
   else
     {
      int t=OrderSend(Symbol(),OP_BUY,lotz,price,slippage,slz,tpz,comment,mg);      
      GlobalVariableSet(Orders[0],t);

      if(nd(sl2,2)) slz=price-atr*sl2;

      lotz=lot2;

      if(risk2)
        {
         lotz = AccountBalance()/100*riskz2;
         lotz = lotz/(nd((MathMax(price,slz)-MathMin(price,slz))/Point(),d))/10;
        }

      dl=MarketInfo(Symbol(),MODE_LOTSTEP)<=0.01 ? 2 :  MarketInfo(Symbol(),MODE_LOTSTEP)<=0.1 ? 1 :
         MarketInfo(Symbol(),MODE_LOTSTEP)<=1? 0 : MarketInfo(Symbol(),MODE_LOTSTEP)<=10 ? -1 : -2;

      lotz=nd(lotz,dl);

      //lotz=NormalizeDouble(MathMax(MathMin(lotz,MarketInfo(Symbol(),MODE_MAXLOT)),MarketInfo(Symbol(),MODE_MINLOT)),2);
       if(lotz>MarketInfo(Symbol(),MODE_MAXLOT))
         lotz=MarketInfo(Symbol(),MODE_MAXLOT);
       if(lotz<MarketInfo(Symbol(),MODE_MINLOT))
         lotz=MarketInfo(Symbol(),MODE_MINLOT);
      tpz=0;

      if(nd(tp2,2))
        {
         if(tpv2==1)
            tpz=price+atr*tp2;
         else
         if(tpv2==2)
           {
            double z=nd(AccountBalance()/100*tp2/(MarketInfo(Symbol(),MODE_TICKSIZE)*lotz),d);
            tpz=price+z*Point();
           }
         else tpz=price+tp2*Point();
        }

      t=OrderSend(Symbol(),OP_BUY,lotz,price,slippage,slz,tpz,comment,mg);
      //         Print(t," Buy22 ",TimeToString(TimeCurrent(),TIME_MINUTES|TIME_SECONDS));
      GlobalVariableSet(Orders[1],t);
      return 1;

     }

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int order_start_s(int &ticket)
  {

   double price=MarketInfo(Symbol(),MODE_BID);

   double atr=iATR(Symbol(),atr_tf,atr_period,0);

   double slz=0;

   if(nd(sl,d)) slz=price+atr*sl;

   double lotz=lot;

   if(risk)
     {
      lotz = AccountBalance()/100*riskz;
      lotz = lotz/(nd((MathMax(price,slz)-MathMin(price,slz))/Point(),d))/10;
     }

   int dl=MarketInfo(Symbol(),MODE_LOTSTEP)<=0.01 ? 2 :  MarketInfo(Symbol(),MODE_LOTSTEP)<=0.1 ? 1 :
          MarketInfo(Symbol(),MODE_LOTSTEP)<=1? 0 : MarketInfo(Symbol(),MODE_LOTSTEP)<=10 ? -1 : -2;

   lotz=nd(lotz,dl);

   lotz=NormalizeDouble(MathMax(MathMin(lotz,MarketInfo(Symbol(),MODE_MAXLOT)),MarketInfo(Symbol(),MODE_MINLOT)),2);

   double tpz=0;

   if(nd(tp,d))
     {
      if(tpv==1)
         tpz=price-atr*tp;
      else
      if(tpv==2)
        {
         double z=nd(AccountBalance()/100*tp/(MarketInfo(Symbol(),MODE_TICKSIZE)*lotz),d);
         tpz=price-z*Point();
        }
      else tpz=price-tp*Point();
     }
   if(!UseATR2orders)
     {
      int t=OrderSend(Symbol(),OP_SELL,lotz,price,slippage,slz,tpz,comment,mg);
      //         Print(t," Sell11 ",TimeToString(TimeCurrent(),TIME_MINUTES|TIME_SECONDS));
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
   else
     {
      int t=OrderSend(Symbol(),OP_SELL,lotz,price,slippage,slz,tpz,comment,mg);
      //         Print(t," Sell21 ",TimeToString(TimeCurrent(),TIME_MINUTES|TIME_SECONDS));
      GlobalVariableSet(Orders[0],t);

      slz=0;

      if(nd(sl2,d)) slz=price+atr*sl2;

      lotz=lot2;

      if(risk2)
        {
         lotz = AccountBalance()/100*riskz2;
         lotz = lotz/(nd((MathMax(price,slz)-MathMin(price,slz))/Point(),d))/10;
        }

      dl=MarketInfo(Symbol(),MODE_LOTSTEP)<=0.01 ? 2 :  MarketInfo(Symbol(),MODE_LOTSTEP)<=0.1 ? 1 :
         MarketInfo(Symbol(),MODE_LOTSTEP)<=1? 0 : MarketInfo(Symbol(),MODE_LOTSTEP)<=10 ? -1 : -2;

      lotz=nd(lotz,dl);

      lotz=NormalizeDouble(MathMax(MathMin(lotz,MarketInfo(Symbol(),MODE_MAXLOT)),MarketInfo(Symbol(),MODE_MINLOT)),2);

      tpz=0;

      if(nd(tp2,d))
        {
         if(tpv2==1)
            tpz=price-atr*tp2;
         else
         if(tpv2==2)
           {
            double z=nd(AccountBalance()/100*tp2/(MarketInfo(Symbol(),MODE_TICKSIZE)*lotz),d);
            tpz=price-z*Point();
           }
         else tpz=price-tp2*Point();
        }
      t=OrderSend(Symbol(),OP_SELL,lotz,price,slippage,slz,tpz,comment,mg);
      //         Print(t," Sell22 ",TimeToString(TimeCurrent(),TIME_MINUTES|TIME_SECONDS));
      GlobalVariableSet(Orders[1],t);
      return 1;
     }

  }
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
/*
int closef(int zaclose)
  {

   int r=1;

   for(int c=OrdersTotal()-1; c>=0; c--)
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
                  r=0;
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
                  r=0;
                  e_ts(GetLastError(),3);
                 }
              }
           }
        }
     }

   return r;

  }
*/
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
/*
string gs_f(string s,int index1,int index2)
  {

   string r="";

   int z_index2=index2 ? MathMin(index1+index2-1,StringLen(s)-1) : StringLen(s)-1;

   for(int c=index1; c<=z_index2; c++) r+=ShortToString(StringGetChar(s,c));

   return r;

  }
*/
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

// åñëè îøèáêà ïîòîðÿåòñÿ ìåíåå 10 ðàç ïîäðÿò, áåç óñïåùíîãî èñïîëíåíèÿ
// âîçâðàòèò çíà÷åíèå false
// â print íàïèøèò êîä îøèáêè
// åñëè îøèáêà ïîòîðÿåòñÿ 10 èëè áîëåå ðàç ïîäðÿò, áåç óñïåùíîãî èñïîëíåíèÿ
// âîçâðàòèò çíà÷åíèå true
// â alert íàïèøèò êîä îøèáêè

string e_ts_vs;
string e_ts_vs2[5]=
  {
   "","the order is not open due to:\n",
   "the order is not modified due to:\n",
   "the order is not closed due to:\n",
   "the order is not delete due to:\n"
  };
int    e_ts_vi=false;
int    e_ts_vi1[5]={0,0,0,0,0};
int    e_ts_vi2[5]={0,0,0,0,0};
int    e_ts_sum=50;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool e_ts(int getlasterror_z,int z)
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

   e_ts_vs=e_ts_vs2[z]+e_ts_vs; // // //

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
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
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
//|                                                                  |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
void GetOrder()
  {

   double SL=0;
   double TP=0;
   double slz=0;
   double atr=0;
   double lotz=0;
   int    Ticket=0;
   //...................................
   Comment("Ti1 :"+Time[1]+" SBTi : "+SecondBuyTime);
   if(Time[1]==SecondBuyTime && SecondEntryRule==true && SecondBuy==true && Close[1]<Open[1] && Open[1]<HighBBand && Close[1]>LowBBand && AtrFilter(0)==true)
    {
               atr=iATR(Symbol(),atr_tf,atr_period,0);
               SecondBuy=false;
               if(nd(sl,2))
                SL=Ask-atr*sl;
               //========================
               lotz=CalcLot(Ask,SL,2);
               //========================
               if(nd(tp,2))
                 {
                     if(tpv==1)
                        TP=Ask+atr*tp;
                     else
                     if(tpv==2)
                       {
                           double z=nd(AccountBalance()/100*tp/(MarketInfo(Symbol(),MODE_TICKSIZE)*lotz),d);
                           TP=Ask+z*Point();
                       }
                     else TP=Ask+tp*Point();
                 }
               //========================
               Ticket=OrderSend(Symbol(),OP_BUY,lotz,Ask,MaxSlippage,SL,TP,"RT2",mg,0,clrBlue);               
               GlobalVariableSet(Orders[1],Ticket);
    }
   //....................................
   if(Time[1]==SecondSellTime && SecondEntryRule==true && SecondSell==true && Close[1]>Open[1] && Close[1]<HighBBand && Open[1]>LowBBand && AtrFilter(1)==true)
    {
               atr=iATR(Symbol(),atr_tf,atr_period,0);
               SecondSell=false;
               if(nd(sl2,2))
                SL=Bid+atr*sl2;
               //========================
               lotz=CalcLot(Bid,SL,2);
               //========================
               if(nd(tp2,2))
                 {
                     if(tpv2==1)
                        TP=Bid-atr*tp2;
                     else
                     if(tpv2==2)
                       {
                           double z=nd(AccountBalance()/100*tp2/(MarketInfo(Symbol(),MODE_TICKSIZE)*lotz),d);
                           TP=Bid-z*Point();
                       }
                     else TP=Bid-tp2*Point();
                 }
               //========================
               Ticket=OrderSend(Symbol(),OP_SELL,lotz,Bid,MaxSlippage,SL,TP,"RT2",mg,0,clrRed);               
               GlobalVariableSet(Orders[1],Ticket);
    }
   //....................................
   if(Trend==0 && TotalOrder(0)==0)
     {
      atr=iATR(Symbol(),atr_tf,atr_period,0);
      if(nd(sl,2))
         SL=Ask-atr*sl;
      //========================
      lotz=CalcLot(Ask,SL,1);
      //========================
      if(nd(tp,2))
        {
         if(tpv==1)
            TP=Ask+atr*tp;
         else
         if(tpv==2)
           {
            double z=nd(AccountBalance()/100*tp/(MarketInfo(Symbol(),MODE_TICKSIZE)*lotz),d);
            TP=Ask+z*Point();
           }
         else TP=Ask+tp*Point();
        }
      //========================
      if(!UseATR2orders)
        {
         Ticket=OrderSend(Symbol(),0,lotz,Ask,MaxSlippage,SL,TP,"RT2",mg,0,clrBlue);
         //         Print(Ticket," Buy11 ",TimeToString(TimeCurrent(),TIME_MINUTES|TIME_SECONDS));
         SecondBuyTime=Time[0];
        }
      else
        {
         Ticket=OrderSend(Symbol(),0,lotz,Ask,MaxSlippage,SL,TP,"RT2",mg,0,clrBlue);
         //         Print(Ticket," Buy21 ",TimeToString(TimeCurrent(),TIME_MINUTES|TIME_SECONDS));
         GlobalVariableSet(Orders[0],Ticket);
         SecondBuy=true;
         SecondBuyTime=Time[0];                   
         Print("BuyOrder "+SecondBuyTime);
         if(SecondEntryRule==false)
          { 
               if(nd(sl,2))
                  SL=Ask-atr*sl;
               //========================
               lotz=CalcLot(Ask,SL,2);
               //========================
               if(nd(tp,2))
                 {
                  if(tpv==1)
                     TP=Ask+atr*tp;
                  else
                  if(tpv==2)
                    {
                     double z=nd(AccountBalance()/100*tp/(MarketInfo(Symbol(),MODE_TICKSIZE)*lotz),d);
                     TP=Ask+z*Point();
                    }
                  else TP=Ask+tp*Point();
                 }
      
               Ticket=OrderSend(Symbol(),0,lotz,Ask,MaxSlippage,SL,TP,"RT2",mg,0,clrBlue);
               //         Print(Ticket," Buy22 ",TimeToString(TimeCurrent(),TIME_MINUTES|TIME_SECONDS));
               GlobalVariableSet(Orders[1],Ticket);
           }
        }
     }
   if(Trend==1 && TotalOrder(1)==0)
     {
      atr=iATR(Symbol(),atr_tf,atr_period,0);
      if(nd(sl,2))
         SL=Bid+atr*sl;
      //========================
      lotz=CalcLot(Bid,SL,1);
      //========================
      if(nd(tp,2))
        {
         if(tpv==1)
            TP=Bid-atr*tp;
         else
         if(tpv==2)
           {
            double z=nd(AccountBalance()/100*tp/(MarketInfo(Symbol(),MODE_TICKSIZE)*lotz),d);
            TP=Bid-z*Point();
           }
         else TP=Bid-tp*Point();
        }
      //========================
      if(!UseATR2orders)
        {
         Ticket=OrderSend(Symbol(),1,lotz,Bid,MaxSlippage,SL,TP,"RT2",mg,0,clrRed);
         //         Print(Ticket," Sell11 ",TimeToString(TimeCurrent(),TIME_MINUTES|TIME_SECONDS));
         SecondSellTime=Time[0];   
        }
      else
        {
         Print("here");
         Ticket=OrderSend(Symbol(),1,lotz,Bid,MaxSlippage,SL,TP,"RT2",mg,0,clrRed);
         //         Print(Ticket," Sell21 ",TimeToString(TimeCurrent(),TIME_MINUTES|TIME_SECONDS));
         GlobalVariableSet(Orders[0],Ticket);
         SecondSell=true; 
         SecondSellTime=Time[0];                   
         if(SecondEntryRule==false)
          {
               if(nd(sl2,2))
                  SL=Bid+atr*sl2;
               //========================
               lotz=CalcLot(Bid,SL,2);
               //========================
               if(nd(tp2,2))
                 {
                  if(tpv2==1)
                     TP=Bid-atr*tp2;
                  else
                  if(tpv2==2)
                    {
                     double z=nd(AccountBalance()/100*tp2/(MarketInfo(Symbol(),MODE_TICKSIZE)*lotz),d);
                     TP=Bid-z*Point();
                    }
                  else TP=Bid-tp2*Point();
                 }
      
               Ticket=OrderSend(Symbol(),1,lotz,Bid,MaxSlippage,SL,TP,"RT2",mg,0,clrRed);
               //         Print(Ticket," Sell22 ",TimeToString(TimeCurrent(),TIME_MINUTES|TIME_SECONDS));
               GlobalVariableSet(Orders[1],Ticket);
          }
        }
     }

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
double CalcLot(double P,double S, int mode)
  {
//---
   if(MoneyManagmentEnable==true)
      return(MoneyManagementFunc(P,S));
   //....
   if(mode==2)
    return(lot2);
   //....
   return(lot);
//---
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
void TrailingStop(int tik)
  {
//---
   bool Check=false;
   for(int i=0; i<=OrdersTotal(); i++)
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true)
        {
         if(OrderTicket()==tik || tik==-1)
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
        }
//---
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void TrailingStop2(int tik)
  {
//---
   bool Check=false;
   for(int i=0; i<=OrdersTotal(); i++)
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true)
        {
         if(OrderTicket()==tik || tik==-1)
           {
            if(OrderType()==0 && OrderMagicNumber()==mg && OrderSymbol()==Symbol())
               if(PipProfit()>TrailStep2 && (StopDistance(0)>=2*TrailStep2 || OrderStopLoss()==0))
                  if((Bid-TrailStep2*_Point)>OrderStopLoss() || OrderStopLoss()==0)
                     Check=OrderModify(OrderTicket(),OrderOpenPrice(),Bid-TrailStep2*_Point,OrderTakeProfit(),OrderExpiration(),clrGold);
            //---
            if(OrderType()==1 && OrderMagicNumber()==mg && OrderSymbol()==Symbol())
               if(PipProfit()>TrailStep2 && (StopDistance(1)>=2*TrailStep2 || OrderStopLoss()==0))
                  if((Ask+TrailStep2*_Point)<OrderStopLoss() || OrderStopLoss()==0)
                     Check=OrderModify(OrderTicket(),OrderOpenPrice(),Ask+TrailStep2*_Point,OrderTakeProfit(),OrderExpiration(),clrGold);
           }
        }
//---
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
double PipProfit()
  {
   double R=OrderProfit()/OrderLots()/MarketInfo(OrderSymbol(),MODE_TICKVALUE);
   return(NormalizeDouble(R,0));
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
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
//|                                                                  |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
void sub_trailing(int tik)
  {
   for(int i=0; i<OrdersTotal(); i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
        {
         if(OrderSymbol()==Symbol() && OrderMagicNumber()==mg)
           {
            if(OrderTicket()==tik || tik==-1)
              {
               if(OrderType()==OP_SELL)
                 {
                  if(OrderOpenPrice()-Ask>BreakEvenPips*point && (OrderStopLoss()>OrderOpenPrice() || OrderStopLoss()==0))
                    {
                     ModifyStopLoss(OrderOpenPrice());
                    }

                  if(OrderStopLoss()-Ask>(BreakEvenPips*2)*point && OrderStopLoss()<=OrderOpenPrice() && BreakEvenType==JUMP_BREAKEVEN)
                    {
                     ModifyStopLoss(Ask+BreakEvenPips*point);
                    }
                 }
               if(OrderType()==OP_BUY)
                 {
                  if(Bid-OrderOpenPrice()>BreakEvenPips*point && (OrderStopLoss()<OrderOpenPrice() || OrderStopLoss()==0))
                    {
                     ModifyStopLoss(OrderOpenPrice());
                    }

                  if(Bid-OrderStopLoss()>(BreakEvenPips*2)*point && OrderStopLoss()>=OrderOpenPrice() && BreakEvenType==JUMP_BREAKEVEN)
                    {
                     ModifyStopLoss(Bid-BreakEvenPips*point);
                    }
                 }
              }
           }
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
void sub_trailing2(int tik)
  {
   for(int i=0; i<OrdersTotal(); i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
        {
         if(OrderSymbol()==Symbol() && OrderMagicNumber()==mg)
           {
            if(OrderTicket()==tik || tik==-1)
              {
               if(OrderType()==OP_SELL)
                 {
                  if(OrderOpenPrice()-Ask>BreakEvenPips2*point && (OrderStopLoss()>OrderOpenPrice() || OrderStopLoss()==0))
                    {
                     ModifyStopLoss(OrderOpenPrice());
                    }

                  if(OrderStopLoss()-Ask>(BreakEvenPips2*2)*point && OrderStopLoss()<=OrderOpenPrice() && BreakEvenType2==JUMP_BREAKEVEN)
                    {
                     ModifyStopLoss(Ask+BreakEvenPips2*point);
                    }
                 }
               if(OrderType()==OP_BUY)
                 {
                  if(Bid-OrderOpenPrice()>BreakEvenPips2*point && (OrderStopLoss()<OrderOpenPrice() || OrderStopLoss()==0))
                    {
                     ModifyStopLoss(OrderOpenPrice());
                    }

                  if(Bid-OrderStopLoss()>(BreakEvenPips2*2)*point && OrderStopLoss()>=OrderOpenPrice() && BreakEvenType2==JUMP_BREAKEVEN)
                    {
                     ModifyStopLoss(Bid-BreakEvenPips2*point);
                    }
                 }
              }
           }
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ModifyStopLoss(double ldStop)
  {
   bool   fm;
   double ldOpen=OrderOpenPrice();
   double ldTake=OrderTakeProfit();

   fm=OrderModify(OrderTicket(),ldOpen,ldStop,ldTake,0,Pink);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
double MoneyManagementFunc(double price,double slz)
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
int NumberOfPositions(string sy="",int op=-1)
  {
   int i,k=OrdersTotal(),kp=0;

   if(sy=="0") sy=Symbol();
   for(i=0; i<k; i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
        {
         if(OrderSymbol()==sy || sy=="")
           {
            if(OrderType()==OP_BUY || OrderType()==OP_SELL)
              {
               if(op<0 || OrderType()==op)
                 {
                  if(mg<0 || OrderMagicNumber()==mg) kp++;
                 }
              }
           }
        }
     }
   return(kp);
  }
//..........................................................................
bool AtrFilter(int T)
  {
//---
      if(AtrFilter_SecondEntry==false)
       return(true);
      //...
      double Atr=NormalizeDouble(iATR(Symbol(),atr_tf,atr_period,0),Digits);
      if(Atr>ATRMin && Atr<ATRMax)
       return(true);      
//---
      return(false);
  }
//..........................................................................