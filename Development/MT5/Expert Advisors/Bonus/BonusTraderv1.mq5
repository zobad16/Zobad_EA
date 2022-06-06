//+------------------------------------------------------------------+
//|                                                        Bonus.mq5 |
//|                                     Copyright 2022, Quantech Sol.|
//|                                          https://quantechsol.com |
//|                                     MA-Crossover
//+------------------------------------------------------------------+
#property copyright "Contact us : Whatsapp: +905469442173"
#property link      "https://quantechsol.com"
#property version   "1.00"
#property strict
#include <Trade\Trade.mqh>
#include <Trade\TerminalInfo.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Controls\Dialog.mqh>
#include <Controls\Button.mqh>
#include <Controls\Label.mqh>
#include <Controls\Edit.mqh>
CEdit   InputParams[3];
CDialog Dialog;
CButton MannualEntryBtn [5];
CButton CloseAllBtn;
CButton CloseBuysBtn;
CButton CloseSellsBtn;
CButton TitleBtn;
CButton SaveBtn;
CLabel  Labels[8];
CLabel  LabelsInputs[8];
CLabel  LabelsValues[8];
color DialogColor= C'16,21,43';
string FontName = "Segoe UI";
color FirstComboBoxColor= C'27,33,59';
color FirstComboBoxBorderColor= C'18,69,99';
color HedgeBtnColor= C'255,136,0';
color HedgeBtnTextColor=clrBlack;
CSymbolInfo    m_symbol;
CPositionInfo  m_position;
CTrade trade;
CTerminalInfo  TerminalInfo;
enum BBM
{
   DIRECTIONAL=0,
   REVERSAL=1




};
enum E_SST
{
   Directional=0,
   Reversal=1,
   Open_Now=2,
   MA_Directional=3,
   MA_Reversal=4,
   Mannual=5,
};
enum E_Grid_Direction
{

Grid_Long=0,//Long
Grid_Short=1,//Short
Grid_Both=2//Both



};

input string               GridSet="------------ Settings -------------------";
input int                  magic_num=46598; //Magic Number
 bool                 Positive_Grid=true;//Positive Grid
 E_Grid_Direction     Grid_Direction=Grid_Both;//Grid Direction
 E_SST                Strategy_Type=Mannual;//Strategy Type
double                     Lot_Size=0.5;// Lot Size
input int                  Grid_Max_Leg=3;//Grid Max Leg
input double               Grid_Leg_Threshold=2500;//Grid Leg Threshold
input double               Grid_Lot_Multiplier=1.50;//Grid Multiplier
bool                 Grid_Hide_TP_SL=false;//Grid Hide TP/SL
 bool                 UsePointStop = false;
double               TP_Point=25000;//TP Point
double               SL_Point=25000;//SL Point
 double               TP_Money=700;//TP Money
 double               SL_Money=2000;//SL Money
input bool                 UseEquityTrail=false;//Use Equity trail
input double               EquityTrailStart= 500;//Equity Trail Start point
input double               Width=200;//Equity trail width
input string               Trade_Comment="Bonus";
 string               Bollinger_Bands_Setting="=====  Bollinger Bands =====";
 int                  BB_Period=20;// Bollinger Bands Period
 double               BB_deviation=2;// Bollinger Bands deviation
 int                  BB_Shift=0;// Bollinger Shift
 ENUM_APPLIED_PRICE   BB_Applied_Price=PRICE_CLOSE;// Bollinger Applied Price
 string  MA_Setting="=====  Moving Average =====";
 int     MovingPeriod       = 50;      // Moving Average period
 int     MovingShift        = 0;       // Moving Average shift
 ENUM_MA_METHOD MA_Method   = MODE_EMA; //Moving Average Method
 ENUM_APPLIED_PRICE  MA_Applied_Price=PRICE_CLOSE;// MA Applied Price
datetime Expiry=D'2022.12.12 00:00';
bool exp_deliverd = false;
double TPB,TPS;
int C_B_N=-1;
int C_S_N=-1;
double GB_N[1000];
double GBL_N[1000];
double GS_N[1000];
double GSL_N[1000];

int C_B_P=-1;
int C_S_P=-1;
double GB_P[1000];
double GBL_P[1000];
double GS_P[1000];
double GSL_P[1000];
double OPB=0;
double Count_B=0;
double OPS=0;
double Count_S=0;
double FTPB=0;
double FTPS=0;
int Handler_BB;
double UPBB1[];
double DNBB1[];
bool reset;
int ExtHandle = 0;
bool useAcl = false;
int Allowed_Acc = 100111;
int Allowed_Acc2 = 1406484;
int Allowed_Acc3 = 100113;
//int Allowed_Acc2 = 14;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
//---
   if(useAcl){
      long curr_acc = AccountInfoInteger(ACCOUNT_LOGIN);
      if(curr_acc != Allowed_Acc && curr_acc != Allowed_Acc2 &&curr_acc != Allowed_Acc3 ){
         Alert("AMG Trade not allowed on this account");
         return (INIT_FAILED);
      }
   }
   if(CheckExpiry())
   {
      Alert("EA expired. Please contact the developer");
      exp_deliverd=true;
      return (INIT_FAILED);
      
   }
   ExtHandle=iMA(_Symbol,_Period,MovingPeriod,MovingShift,MA_Method,MA_Applied_Price);
   if(ExtHandle==INVALID_HANDLE)
     {
      printf("Error creating MA indicator");
      return(INIT_FAILED);
     }
   trade.SetExpertMagicNumber(magic_num);
   Handler_BB=iBands(NULL,0,BB_Period,BB_Shift,BB_deviation,BB_Applied_Price);
   Dialog.Create(ChartID(),"                             WWW.QUANTECHSOL.COM",0,5,5,720,350);
   string dialogNumber=Dialog.Name();
   ObjectSetInteger(ChartID(),dialogNumber+"Caption",OBJPROP_BGCOLOR,clrOrange);
   ObjectSetInteger(ChartID(),dialogNumber+"ClientBack",OBJPROP_BGCOLOR,clrWhite);
   
   ObjectDelete(ChartID(),dialogNumber+"Border");
   
   TitleBtn.Create(0,"OpenHedge",0,15,16,0,0)                              ;
   TitleBtn.Text("AUTO START")                                            ;
   TitleBtn.FontSize(10)                                          ;
   TitleBtn.Font(FontName);                                    
   TitleBtn.Height(35)                                            ;
   TitleBtn.Width(200)                                            ;
   TitleBtn.Color(clrWhite)                                       ;
   TitleBtn.ColorBackground(clrBlue)                             ;
   TitleBtn.ColorBorder(clrBlack)                                 ;
   TitleBtn.Disable()                                             ;
   Dialog.Add(TitleBtn);
   MannualEntryBtn[2].Create(0,"OpenManual",0,215,16,0,0)                ;
   MannualEntryBtn[2].Text("START MANUAL")                                ;
   MannualEntryBtn[2].FontSize(11)                                    ;   
   MannualEntryBtn[2].Font(FontName);                                  
   MannualEntryBtn[2].Height(35)                                      ;
   MannualEntryBtn[2].Width(200)                                      ;
   MannualEntryBtn[2].Color(clrWhite)                                 ;
   MannualEntryBtn[2].ColorBackground(clrBlue)                        ;
   MannualEntryBtn[2].ColorBorder(clrBlack)                           ;
   MannualEntryBtn[2].Pressed(false);
   Dialog.Add(MannualEntryBtn[2]);
   
      
   MannualEntryBtn[0].Create(0,"OpenBuy",0,15,50,0,0)                ;
   MannualEntryBtn[0].Text("BUY")                                ;
   MannualEntryBtn[0].FontSize(11)                                    ;   
   MannualEntryBtn[0].Font(FontName);                                  
   MannualEntryBtn[0].Height(35)                                      ;
   MannualEntryBtn[0].Width(200)                                      ;
   MannualEntryBtn[0].Color(clrWhite)                                 ;
   MannualEntryBtn[0].ColorBackground(clrBlue)                        ;
   MannualEntryBtn[0].ColorBorder(clrBlack)                           ;
   MannualEntryBtn[0].Pressed(false);
   Dialog.Add(MannualEntryBtn[0]);
   
   CloseBuysBtn.Create(0,"CloseBuys",0,15,84,0,0)                      ;
   CloseBuysBtn.Text("CLOSE BUYS")                                     ;
   CloseBuysBtn.FontSize(11)                                          ;   
   CloseBuysBtn.Font(FontName);                                  
   CloseBuysBtn.Height(35)                                            ;
   CloseBuysBtn.Width(200)                                            ;
   CloseBuysBtn.Color(clrWhite)                                       ;
   CloseBuysBtn.ColorBackground(clrBlue)                               ;
   CloseBuysBtn.ColorBorder(clrBlack)                                 ;
   CloseBuysBtn.Pressed(false);
   Dialog.Add(CloseBuysBtn);
   
   MannualEntryBtn[1].Create(0,"OpenSell",0,215,50,0,0)                      ;
   MannualEntryBtn[1].Text("SELL")                                     ;
   MannualEntryBtn[1].FontSize(11)                                          ;                                    
   MannualEntryBtn[1].Height(35)                                            ;
   MannualEntryBtn[1].Width(200)                                            ;
   MannualEntryBtn[1].Color(clrWhite)                                       ;
   MannualEntryBtn[1].ColorBackground(clrRed)                               ;
   MannualEntryBtn[1].ColorBorder(clrBlack)                                 ;
   MannualEntryBtn[1].Pressed(false);
   Dialog.Add(MannualEntryBtn[1]);
   
   reset = false                                                     ; 
   CloseSellsBtn.Create(0,"CloseSells",0,215,84,0,0)                      ;
   CloseSellsBtn.Text("CLOSE SELLS")                                     ;
   CloseSellsBtn.FontSize(11)                                          ;                                    
   CloseSellsBtn.Height(35)                                            ;
   CloseSellsBtn.Width(200)                                            ;
   CloseSellsBtn.Color(clrWhite)                                       ;
   CloseSellsBtn.ColorBackground(clrRed)                               ;
   CloseSellsBtn.ColorBorder(clrBlack)                                 ;
   CloseSellsBtn.Pressed(false);
   Dialog.Add(CloseSellsBtn);
   
   CloseAllBtn.Create(0,"CloseAll",0,15,118,0,0)                      ;
   CloseAllBtn.Text("CLOSE TRADES")                                     ;
   CloseAllBtn.FontSize(11)                                          ;                                    
   CloseAllBtn.Height(35)                                            ;
   CloseAllBtn.Width(400)                                            ;
   CloseAllBtn.Color(clrWhite)                                       ;
   CloseAllBtn.ColorBackground(clrMaroon)                             ;
   CloseAllBtn.ColorBorder(clrBlack)                                 ;
   CloseAllBtn.Pressed(false);
   Dialog.Add(CloseAllBtn);
   
   LabelsInputs[0].Create(0,"LotsLbl",0,15,168,0,0);
   LabelsInputs[0].Text("Lots: ");
   LabelsInputs[0].FontSize(9);
   Dialog.Add(LabelsInputs[0]);
   LabelsInputs[1].Create(0,"ProfitLbl",0,15,195,0,0);
   LabelsInputs[1].Text("Profit$: ");
   LabelsInputs[1].FontSize(9);
   Dialog.Add(LabelsInputs[1]);
   LabelsInputs[2].Create(0,"LossLbl",0,15,225,0,0);
   LabelsInputs[2].Text("Loss$: ");
   LabelsInputs[2].FontSize(9);
   Dialog.Add(LabelsInputs[2]);
   
   InputParams[0].Create(0,"LotsEdit",0,80,165,0,0)                    ;
   InputParams[0].Text(""+(string)Lot_Size)                                          ;
   InputParams[0].FontSize(10)                                          ;
   InputParams[0].Height(25)                                           ;
   InputParams[0].Width(330)                                           ;
   Dialog.Add(InputParams[0])                                          ;
   InputParams[1].Create(0,"ProfitEdit",0,80,195,0,0)                    ;
   InputParams[1].Text(""+(string)TP_Money)                                          ;
   InputParams[1].FontSize(10)                                          ;
   InputParams[1].Height(25)                                           ;
   InputParams[1].Width(330)                                           ;
   Dialog.Add(InputParams[1])                                          ;
   InputParams[2].Create(0,"LossEdit",0,80,225,0,0)                    ;
   InputParams[2].Text(""+(string)SL_Money)                                          ;
   InputParams[2].FontSize(10)                                          ;
   InputParams[2].Height(25)                                           ;
   InputParams[2].Width(330)                                           ;
   Dialog.Add(InputParams[2])                                          ;
   SaveBtn.Create(0,"ApplyBtn",0,15,254,0,0)                      ;
   SaveBtn.Text("APPLY")                                     ;
   SaveBtn.FontSize(11)                                          ;                                    
   SaveBtn.Height(35)                                            ;
   SaveBtn.Width(400)                                            ;
   SaveBtn.Color(clrBlack)                                       ;
   SaveBtn.ColorBackground(clrLime)                               ;
   SaveBtn.ColorBorder(clrBlack)                                 ;
   SaveBtn.Pressed(false);
   Dialog.Add(SaveBtn);
   
   
   
   Labels[0].Create(0,"NPnlLbl",0,530,35,30,0);
   Labels[0].Text("NET PNL$: ");
   Labels[0].FontSize(10);
   Labels[0].Color(clrDarkBlue);   
   
   Dialog.Add(Labels[0]);
   LabelsValues[0].Create(0,"NPNLValue",0,620,35,30,0);
   LabelsValues[0].Text("0.0");
   LabelsValues[0].FontSize(10);
   LabelsValues[0].Color(clrDarkBlue);
   Dialog.Add(LabelsValues[0]);
   Labels[1].Create(0,"BPnlLbl",0,530,55,30,0);
   Labels[1].Text("BUY PNL$: ");
   Labels[1].FontSize(9);
   Labels[1].Color(clrSlateGray);
   Dialog.Add(Labels[1]);
   LabelsValues[1].Create(0,"BPNLValue",0,620,55,30,0);
   LabelsValues[1].Text("0.0");
   LabelsValues[1].FontSize(9);
   LabelsValues[1].Color(clrSlateGray);
   Dialog.Add(LabelsValues[1]);   
   Labels[2].Create(0,"SPnlLbl",0,530,75,30,0);
   Labels[2].Text("SELL PNL$: ");
   Labels[2].FontSize(9);
   Labels[2].Color(clrSlateGray);
   Dialog.Add(Labels[2]);
   LabelsValues[2].Create(0,"SPNLValue",0,620,75,30,0);
   LabelsValues[2].Text("0.0");
   LabelsValues[2].FontSize(9);
   LabelsValues[2].Color(clrSlateGray);
   Dialog.Add(LabelsValues[2]);
   Labels[3].Create(0,"BLegsLbl",0,530,95,30,0);
   Labels[3].Text("BUY Legs: ");
   Labels[3].FontSize(9);
   Labels[3].Color(clrSlateGray);
   Dialog.Add(Labels[3]);
   LabelsValues[3].Create(0,"BLegsValue",0,620,95,30,0);
   LabelsValues[3].Text("0.0");
   LabelsValues[3].FontSize(9);
   LabelsValues[3].Color(clrSlateGray);
   Dialog.Add(LabelsValues[3]);
   Labels[4].Create(0,"SLegsLbl",0,530,115,30,0);
   Labels[4].Text("SELL Legs: ");
   Labels[4].FontSize(9);
   Labels[4].Color(clrSlateGray);
   Dialog.Add(Labels[4]);
   LabelsValues[4].Create(0,"SLegsValue",0,620,115,30,0);
   LabelsValues[4].Text("0.0");
   LabelsValues[4].FontSize(9);
   LabelsValues[4].Color(clrSlateGray);
   Dialog.Add(LabelsValues[4]);
   
   
   
   EventSetMillisecondTimer(300);
   
   
   
//---
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
//---
   Dialog.Destroy(reason);
   EventKillTimer();
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTimer(){
   if(!TerminalInfo.IsTradeAllowed() || exp_deliverd)
      return;
   int legs = Orders();
   int blegs= OrdersTT(POSITION_TYPE_BUY);
   int slegs= OrdersTT(POSITION_TYPE_SELL);
   double pnl = GetPnl();
   double bpnl= GetPnl(POSITION_TYPE_BUY);
   double spnl= GetPnl(POSITION_TYPE_SELL);
   string dir = "";
    int op = -99;
   if(Grid_Direction == Grid_Long){ 
      op= POSITION_TYPE_BUY;        
      dir = "Long";
   }   
   else if(Grid_Direction == Grid_Short){
      dir = "Short";
      op = POSITION_TYPE_SELL;  
   }   
   else if(Grid_Direction == Grid_Both)  {
    dir = "Both";
   }
   LabelsValues[0].Text(DoubleToString(pnl,2));
   LabelsValues[1].Text(DoubleToString(bpnl,2));
   LabelsValues[2].Text(DoubleToString(spnl,2));
   LabelsValues[3].Text((string)blegs);
   LabelsValues[4].Text((string)slegs);
}

void OnTick()
{
//---
   
   //if(!IsExpertEnabled()) return;
   if(!TerminalInfo.IsTradeAllowed())
      return;
   if(CheckExpiry()){
      if(!exp_deliverd){
         exp_deliverd = true;
         Alert("EA expired. Please contact the developer");
      }
      else
         return;
   }
int orders_total = Orders();
if(orders_total == 0){
   Refresh_Buy();
   Refresh_Sell();
   if(Strategy_Type==2 && (Grid_Direction==0||Grid_Direction==2) && OrdersTT(0)==0)
   {
      
      Refresh_Sell();
          bool buy = false;
          if(UsePointStop)buy = trade.Buy(Lot_Size,NULL,SymbolInfoDouble(Symbol(),SYMBOL_ASK),SymbolInfoDouble(Symbol(),SYMBOL_ASK)-SL_Point*Point(),SymbolInfoDouble(Symbol(),SYMBOL_ASK)+TP_Point*Point(),Trade_Comment);  
          else buy = trade.Buy(Lot_Size,NULL,SymbolInfoDouble(Symbol(),SYMBOL_ASK),0,0,Trade_Comment);
          if(buy){
            C_B_N=0;
            GB_N[C_B_N]=SymbolInfoDouble(Symbol(),SYMBOL_ASK);
            GBL_N[C_B_N]=Lot_Size;
            C_B_P=0;
            GB_P[C_B_P]=SymbolInfoDouble(Symbol(),SYMBOL_ASK);
            GBL_P[C_B_P]=Lot_Size;
            OPB=SymbolInfoDouble(Symbol(),SYMBOL_ASK)+OPB;
            Count_B++;
            FTPB=SymbolInfoDouble(Symbol(),SYMBOL_ASK)+TP_Point*Point();
          }  
     
     
     
     }
     
     if(Strategy_Type==2 && (Grid_Direction==1||Grid_Direction==2) && OrdersTT(1)==0)
    {
    
     
              Refresh_Buy();
        
            bool sell = false;
            if(UsePointStop) sell = trade.Sell(Lot_Size,NULL,SymbolInfoDouble(Symbol(),SYMBOL_BID),SymbolInfoDouble(Symbol(),SYMBOL_BID)+SL_Point*Point(),SymbolInfoDouble(Symbol(),SYMBOL_BID)-TP_Point*Point(),Trade_Comment);    
            else sell = trade.Sell(Lot_Size,NULL,SymbolInfoDouble(Symbol(),SYMBOL_BID),0,0,Trade_Comment);    
            if(sell){
               C_S_N=0;
               GS_N[C_S_N]=SymbolInfoDouble(Symbol(),SYMBOL_BID);
               GSL_N[C_S_N]=Lot_Size;
               C_S_P=0;
               GS_P[C_S_P]=SymbolInfoDouble(Symbol(),SYMBOL_BID);
               GSL_P[C_S_P]=Lot_Size;
               OPS=SymbolInfoDouble(Symbol(),SYMBOL_BID)+OPS;
               Count_S++;
               FTPS=SymbolInfoDouble(Symbol(),SYMBOL_BID)-TP_Point*Point();
            }
     }
     
     else if(Strategy_Type == MA_Directional || Strategy_Type == MA_Reversal){
      int signal_ma = MA_Check();
      if(signal_ma == 1){
         Refresh_Sell();
         bool buy = false;
          if(UsePointStop)buy = trade.Buy(Lot_Size,NULL,SymbolInfoDouble(Symbol(),SYMBOL_ASK),SymbolInfoDouble(Symbol(),SYMBOL_ASK)-SL_Point*Point(),SymbolInfoDouble(Symbol(),SYMBOL_ASK)+TP_Point*Point(),Trade_Comment);  
          else buy = trade.Buy(Lot_Size,NULL,SymbolInfoDouble(Symbol(),SYMBOL_ASK),0,0,Trade_Comment);
          if(buy){
            C_B_N=0;
            GB_N[C_B_N]=SymbolInfoDouble(Symbol(),SYMBOL_ASK);
            GBL_N[C_B_N]=Lot_Size;
            C_B_P=0;
            GB_P[C_B_P]=SymbolInfoDouble(Symbol(),SYMBOL_ASK);
            GBL_P[C_B_P]=Lot_Size;
            OPB=SymbolInfoDouble(Symbol(),SYMBOL_ASK)+OPB;
            Count_B++;
            FTPB=SymbolInfoDouble(Symbol(),SYMBOL_ASK)+TP_Point*Point();
         }
      }
      else if(signal_ma == -1 ){
         Refresh_Buy();
         bool sell = false;
         if(UsePointStop) sell = trade.Sell(Lot_Size,NULL,SymbolInfoDouble(Symbol(),SYMBOL_BID),SymbolInfoDouble(Symbol(),SYMBOL_BID)+SL_Point*Point(),SymbolInfoDouble(Symbol(),SYMBOL_BID)-TP_Point*Point(),Trade_Comment);    
         else sell = trade.Sell(Lot_Size,NULL,SymbolInfoDouble(Symbol(),SYMBOL_BID),0,0,Trade_Comment);    
         if(sell){
               C_S_N=0;
               GS_N[C_S_N]=SymbolInfoDouble(Symbol(),SYMBOL_BID);
               GSL_N[C_S_N]=Lot_Size;
               C_S_P=0;
               GS_P[C_S_P]=SymbolInfoDouble(Symbol(),SYMBOL_BID);
               GSL_P[C_S_P]=Lot_Size;
               OPS=SymbolInfoDouble(Symbol(),SYMBOL_BID)+OPS;
               Count_S++;
               FTPS=SymbolInfoDouble(Symbol(),SYMBOL_BID)-TP_Point*Point();
         }
     }

   }
   
   }      
   else{
         CheckLoss();
         EquityTrail(UseEquityTrail,EquityTrailStart,Width);
      }

//***********************************************************

   if(Positive_Grid)
   {
      int order = Orders();
      Count_B   = OrdersTTUpdated(POSITION_TYPE_BUY);
      Count_S   = OrdersTTUpdated(POSITION_TYPE_SELL);
      if( order!=0)
      {
         
         //Need to check legs
         if(Count_B<Grid_Max_Leg+1){
            double lots = 0.0;
            double lst_price =  LastOrderPrice(ORDER_TYPE_BUY,lots);
            if(SymbolInfoDouble(Symbol(),SYMBOL_ASK)>=(lst_price+Grid_Leg_Threshold*Point()))
            {
               Print("Total Orders: ["+order+"] Leg trigger-Buy["+IntegerToString(Count_B)+"] Starting Lot: "+Lot_Size);
               if( (Grid_Direction==0||Grid_Direction==2)){
               //|| (Strategy_Type == MA_Directional || Strategy_Type == MA_Reversal || Strategy_Type == Mannual ))
               
                  double average_price_buy = Average_Open_Price(POSITION_TYPE_BUY);
                  
                  OPB=SymbolInfoDouble(Symbol(),SYMBOL_ASK)+OPB;
                  double lot_size_G=NormalizeDouble(MathPow(Grid_Lot_Multiplier,C_B_P)*Lot_Size,2);
                  double lot_size_diff = NormalizeDouble(Lot_Size*MathPow(Grid_Lot_Multiplier,Count_B),2);
                  Print("Buy grid leg["+(Count_B)+"] lotg["+DoubleToString(lot_size_G)+"] lotdiff["+DoubleToString(lot_size_diff)+"]");
                  if(trade.Buy(lot_size_diff,NULL,SymbolInfoDouble(Symbol(),SYMBOL_ASK),0,0,Trade_Comment))
                  {
                     C_B_P++;
                     GB_P[C_B_P]=SymbolInfoDouble(Symbol(),SYMBOL_ASK);
                     GBL_P[C_B_P]=lot_size_G;
                     Print("AVG["+average_price_buy+"]OPB["+OPB+"] Count_B["+Count_B+"] SL_Point*point["+(SL_Point*Point())+"] point[]");
                     if(UsePointStop)Average_SL((average_price_buy)-SL_Point*Point() );
                  
                  }                  
               }
            }         
         }
         if(Count_S<Grid_Max_Leg+1)
         {
            double lst_price = LastOrderPrice(ORDER_TYPE_SELL);
            if( (Grid_Direction==1||Grid_Direction==2)){
            //|| (Strategy_Type == MA_Directional || Strategy_Type == MA_Reversal|| Strategy_Type == Mannual)){
               if(SymbolInfoDouble(Symbol(),SYMBOL_BID)<=(lst_price-Grid_Leg_Threshold*Point()))
               {
                  Print("Total Orders: ["+order+"] Leg trigger-Sell["+(Count_S)+"] Starting Lot: "+Lot_Size);
                  double average_price_sell = Average_Open_Price(POSITION_TYPE_SELL);
                  OPS=SymbolInfoDouble(Symbol(),SYMBOL_BID)+OPS;
                  double lot_size_G=NormalizeDouble(MathPow(Grid_Lot_Multiplier,C_S_P)*Lot_Size,2);            
                  double lot_size_diff = NormalizeDouble(Lot_Size*MathPow(Grid_Lot_Multiplier,Count_S),2);
                  Print("Sell grid leg["+(Count_S)+"] lotg["+DoubleToString(lot_size_G)+"] lotdiff["+DoubleToString(lot_size_diff)+"]");
                  
                  bool sell = trade.Sell(lot_size_diff,NULL,SymbolInfoDouble(Symbol(),SYMBOL_BID),0,0,Trade_Comment);
                  if(sell){
                     C_S_P++;
                     GS_P[C_S_P]=SymbolInfoDouble(Symbol(),SYMBOL_BID);
                     GSL_P[C_S_P]=lot_size_G;
                     Print("AVG["+DoubleToString(average_price_sell,Digits())+"] OPS["+IntegerToString(OPS)+"] Count_S["+IntegerToString(Count_S)+"] SL_Point*point["+(SL_Point*Point())+"] point[]");
                     if(UsePointStop)Average_SL((average_price_sell)+SL_Point*Point() );            
                  }
               }
            }               
         }
      }
      if(Grid_Direction == Grid_Both){
      int buy_legs = OrdersTT(POSITION_TYPE_BUY);
      int sell_legs = OrdersTT(POSITION_TYPE_SELL);
      if(buy_legs>0 && sell_legs == 0){
        Print("opening sell- Reason both");
        bool sell = false;
         if(UsePointStop) sell = trade.Sell(Lot_Size,NULL,SymbolInfoDouble(Symbol(),SYMBOL_BID),SymbolInfoDouble(Symbol(),SYMBOL_BID)+SL_Point*Point(),SymbolInfoDouble(Symbol(),SYMBOL_BID)-TP_Point*Point(),Trade_Comment);    
         else sell = trade.Sell(Lot_Size,NULL,SymbolInfoDouble(Symbol(),SYMBOL_BID),0,0,Trade_Comment);    
         
            if(sell){
               C_S_N=0;
               GS_N[C_S_N]=SymbolInfoDouble(Symbol(),SYMBOL_BID);
               GSL_N[C_S_N]=Lot_Size;
               C_S_P=0;
               GS_P[C_S_P]=SymbolInfoDouble(Symbol(),SYMBOL_BID);
               GSL_P[C_S_P]=Lot_Size;
               OPS=SymbolInfoDouble(Symbol(),SYMBOL_BID)+OPS;
               Count_S++;
               FTPS=SymbolInfoDouble(Symbol(),SYMBOL_BID)-TP_Point*Point();
            }    
         
      }
      else if(buy_legs==0 && sell_legs > 0){
         Print("opening buy- Reason both");
         bool buy = false;
         if(UsePointStop)buy = trade.Buy(Lot_Size,NULL,SymbolInfoDouble(Symbol(),SYMBOL_ASK),SymbolInfoDouble(Symbol(),SYMBOL_ASK)-SL_Point*Point(),SymbolInfoDouble(Symbol(),SYMBOL_ASK)+TP_Point*Point(),Trade_Comment);  
          else buy = trade.Buy(Lot_Size,NULL,SymbolInfoDouble(Symbol(),SYMBOL_ASK),0,0,Trade_Comment);
          if(buy){
               C_B_N=0;
               GB_N[C_B_N]=SymbolInfoDouble(Symbol(),SYMBOL_ASK);
               GBL_N[C_B_N]=Lot_Size;
               C_B_P=0;
               GB_P[C_B_P]=SymbolInfoDouble(Symbol(),SYMBOL_ASK);
               GBL_P[C_B_P]=Lot_Size;
               OPB=SymbolInfoDouble(Symbol(),SYMBOL_ASK)+OPB;
               Count_B++;
               FTPB=SymbolInfoDouble(Symbol(),SYMBOL_ASK)+TP_Point*Point();
             } 
      }
   }
      /*if(Orders()!=0)
      {
         if(OrdersTT(ORDER_TYPE_SELL)<Grid_Max_Leg+1)
         {
            GB_P[C_S_P] = LastOrderPrice(ORDER_TYPE_SELL);
            if( (Grid_Direction==1||Grid_Direction==2)){
            //|| (Strategy_Type == MA_Directional || Strategy_Type == MA_Reversal|| Strategy_Type == Mannual)){
               if(SymbolInfoDouble(Symbol(),SYMBOL_BID)<=(GS_P[C_S_P]-Grid_Leg_Threshold*Point()))
               {
                  double average_price_sell = Average_Open_Price(POSITION_TYPE_SELL);
                  OPS=SymbolInfoDouble(Symbol(),SYMBOL_BID)+OPS;
                  Count_S++;
                  double lot_size_G=NormalizeDouble(MathPow(Grid_Lot_Multiplier,C_S_P)*Lot_Size,2);            
                  bool sell = trade.Sell(lot_size_G,NULL,SymbolInfoDouble(Symbol(),SYMBOL_BID),0,FTPS,Trade_Comment);
                  if(sell){
                     C_S_P++;
                     GS_P[C_S_P]=SymbolInfoDouble(Symbol(),SYMBOL_BID);
                     GSL_P[C_S_P]=lot_size_G;
                     //Print("AVG["+average_price_sell+"] OPS["+OPS+"] Count_S["+Count_S+"] SL_Point*point["+(SL_Point*Point())+"] point[]");
                     Average_SL((average_price_sell)+SL_Point*Point() );            
                  }
                  else{
                     Count_S--;
                  }
               }
            }               
         }
       }*/
   }
//*******************************************************************

   if(Strategy_Type!=2)
   {
      if(TP_Point!=0 && UsePointStop)
      {
         TPB=SymbolInfoDouble(Symbol(),SYMBOL_ASK)+TP_Point*Point();
         TPS=SymbolInfoDouble(Symbol(),SYMBOL_BID)-TP_Point*Point();
   
   
      }
      else
      {
         TPB=0;
         TPS=0;
      }
      if(Orders()==0 && iVolume(NULL,PERIOD_CURRENT,0)<=1)
      {
         if(BB_Check()==1 && Orders()==0&&  (Grid_Direction==0||Grid_Direction==2) )
         {
            Refresh_Sell();
            double _ask = SymbolInfoDouble(Symbol(),SYMBOL_ASK);
            //   int BuyTicket=OrderSend(Symbol(),OP_BUY,Lot_Size,Ask,5,Ask-SL_Point*Point,TPB,Trade_Comment,magic_num,0,clrNONE);
            if(trade.Buy(Lot_Size,NULL,_ask,/*_ask-(SL_Point*Point())*/0,TPB,Trade_Comment)){
               C_B_N=0;
               GB_N[C_B_N]=_ask;
               GBL_N[C_B_N]=Lot_Size;
               C_B_P=0;
               GB_P[C_B_P]=_ask;
               GBL_P[C_B_P]=Lot_Size;
               OPB=_ask+OPB;
               Count_B++;
               FTPB=TPB;
            }
            
         }
   
         if(BB_Check()==-1 && Orders()==0&&  (Grid_Direction==1||Grid_Direction==2))
         {
            Refresh_Buy();
            double _bid = SymbolInfoDouble(Symbol(),SYMBOL_BID);
            // int SellTicket=OrderSend(Symbol(),OP_SELL,Lot_Size,Bid,5,Bid+SL_Point*Point,TPS,Trade_Comment,magic_num,0,clrNONE);
            if(trade.Sell(Lot_Size,NULL,_bid,/*_bid+(SL_Point*Point())*/0,TPS,Trade_Comment)){
               C_S_N=0;
               GS_N[C_S_N]=_bid;
               GSL_N[C_S_N]=Lot_Size;
               C_S_P=0;
               GS_P[C_S_P]=_bid;
               GSL_P[C_S_P]=Lot_Size;
               OPS=_bid+OPS;
               Count_S++;
               FTPS=TPS;
            }
            
         }
   
   
      }
      if(OrdersTT(0)==0)
      {
         OPB=0;
         Count_B=0;
   
      }
      if(OrdersTT(1)==0)
      {
         OPS=0;
         Count_S=0;
   
      }
   }
}
double LotsCalculatePositiveGrid(int legs){
   double lot = Lot_Size;
   for(int i = 1; i<=legs; i++){
      lot = lot * Grid_Lot_Multiplier; 
   }
   return lot;
}
double PointsSignal(int op){
   int legs = Orders();
   //Print("Opened Legs: "+legs);
    double last_price = LastOrderPrice(op);
    double next_price = 0.0;
    MqlTick tick;
    if(!SymbolInfoTick(_Symbol,tick)) { Print("no tick data available, error = ",GetLastError()); ExpertRemove(); return -99; }
    else
    {
      
       double _ask=tick.ask;
       double _bid=tick.bid;
         if(op == POSITION_TYPE_BUY){
            next_price = (last_price+ Grid_Leg_Threshold*Point());     
         }
         else if(op == POSITION_TYPE_SELL){
            if(_ask <= last_price- Grid_Leg_Threshold*Point()){
               next_price = (last_price- Grid_Leg_Threshold*Point());
            }
         }
        return next_price; 
     }    
   //return 0.0;
}
double Average_Open_Price(int op)
{
   int count = 0;
   double sum = 0.0;
   double avg = 0.0;
   for(int i=PositionsTotal()-1; i>=0; i--){ // returns the number of current positions
      if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
         if(m_position.Magic()==magic_num && m_position.PositionType() == (ENUM_POSITION_TYPE)op)
         {
            count ++;
            sum += m_position.PriceOpen();
         }   
   }
   avg = sum/count;
   return avg;           
}
int MA_Check()
{
    if(Strategy_Type==MA_Directional || Strategy_Type == MA_Reversal){
      int signal = 0;
      double   ma[1];
      if(CopyBuffer(ExtHandle,0,0,1,ma)!=1)
        {
         Print("CopyBuffer from iMA failed, no data");
         return 0;
        }
      double open = iOpen(Symbol(),0,0);    
      int k=0;
      MqlTick tick;
      if(!SymbolInfoTick(_Symbol,tick)) { Print("no tick data available, error = ",GetLastError()); ExpertRemove(); return -99; }
       double Ask=tick.ask;
       double Bid=tick.bid;
      if((Ask >= ma[0] && open < ma[0]) && Strategy_Type==MA_Directional  )signal = 1;
      else if((Bid <= ma[0] && open > ma[0])&& Strategy_Type==MA_Directional) signal = -1;
      if((Ask >= ma[0] && open < ma[0]) && Strategy_Type==MA_Reversal  )signal = -1;
      else if((Bid <=ma[0] && open > ma[0])&& Strategy_Type==MA_Reversal) signal = 1;
      return signal;   
    }
   else{
      return 0;
   }
   
   
   

}

bool CheckExpiry()
{
   MqlDateTime str1, str2;
   TimeToStruct(Expiry,str1);
   TimeToStruct(TimeCurrent(),str2);  
   if(str2.day >= str1.day && str2.mon >= str1.mon && str2.year >= str1.year)
      return true;
   else
      return false;   
}
  //+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
  {
//---
   Dialog.OnEvent(id,lparam,dparam,sparam);
   if(id == CHARTEVENT_OBJECT_CLICK){
      if(sparam == "")
      return;
    if(sparam=="CloseAll") // Close all
    {
        //CloseAll(Magic);
        //CloseAllBtn.Pressed(false);
        MessageBox("Closing All Orders!")                           ;
        CloseAllPositions();
        CloseAllBtn.Pressed(false);
        //WindowRedraw();
        reset = true;
        Refresh_Buy();
        Refresh_Sell();
    }
    if(sparam=="OpenBuy") // Close Buys
    {
        //CloseAll(Magic);
        MannualEntryBtn[0].Pressed(false);
        MessageBox("Opening Buy Order!")                           ;
        MannualEntry(ORDER_TYPE_BUY);
        //MannualEntry(OP_BUY);
        Print("Opened Buy Position");
        //WindowRedraw();
    }
    if(sparam=="CloseBuys") // Close Buys
    {
        //CloseAll(Magic);
        CloseBuysBtn.Pressed(false);
        MessageBox("Closing All Buy Orders!")                           ;
        CloseAllPositions(POSITION_TYPE_BUY);
        Print("Close All Buy Orders event");
        //WindowRedraw();
        reset = true;
        Refresh_Buy();
    }
    if(sparam=="OpenSell") // Close Buys
    {
        //CloseAll(Magic);
        MannualEntryBtn[1].Pressed(false);
        MessageBox("Opening Sell Order!")                           ;
        MannualEntry(ORDER_TYPE_SELL);
        //MannualEntry(OP_SELL);
        Print("Opened Sell Position");
        //WindowRedraw();
    }
    if(sparam=="CloseSells") // Close Sells
    {
        //CloseAll(Magic);
        CloseSellsBtn.Pressed(false);
        MessageBox("Closing All sell Orders!")                           ;
        CloseAllPositions(POSITION_TYPE_SELL);
        Print("Close All Sell Orders event");
        //WindowRedraw();
        reset = true;
        Refresh_Sell();
    }
    if(sparam =="ApplyBtn"){
      SetParameters();
      MessageBox("Applying parameters");
    }
    if(sparam == "OpenHedge"){      
      MessageBox("Opening hedge positions and stating auto mode");
      Strategy_Type = Open_Now;
      MannualEntry(ORDER_TYPE_SELL);
      MannualEntry(ORDER_TYPE_BUY);
      TitleBtn.Pressed(false);
    }
    if(sparam == "OpenManual"){      
      MessageBox("Opening hedge positions and starting manual mode");
      Strategy_Type = Mannual;
      MannualEntry(ORDER_TYPE_SELL);
      MannualEntry(ORDER_TYPE_BUY);
      MannualEntryBtn[2].Pressed(false);
    }
   }
    
   
}
void SetParameters()
{
   Lot_Size         = StringToDouble(InputParams[0].Text());
   TP_Money         = StringToDouble(InputParams[1].Text());
   SL_Money         = StringToDouble(InputParams[2].Text());
}
//+------------------------------------------------------------------+
int BB_Check()
{
   int k=0;
   MqlTick tick;
    if(!SymbolInfoTick(_Symbol,tick)) { Print("no tick data available, error = ",GetLastError()); ExpertRemove(); return -99; }
    double Ask=tick.ask;
    double Bid=tick.bid;
    
   CopyBuffer(Handler_BB,1,0,1,UPBB1);
   CopyBuffer(Handler_BB,2,0,1,DNBB1);
//  double UPBB1=iBands(NULL,0,BB_Period,BB_Shift,BB_deviation,BB_Applied_Price,MODE_UPPER,1);
//  double   DNBB1=iBands(NULL,0,BB_Period,BB_deviation,BB_Shift,BB_Applied_Price,MODE_LOWER,1);
   if(Ask>=UPBB1[0] && Strategy_Type==0)
      k=1;
   if(Ask>=UPBB1[0] && Strategy_Type==1)
      k=-1;
   if(iOpen(NULL,0,1)<=UPBB1[0] && iClose(NULL,0,1)>=UPBB1[0]  && Strategy_Type==0)
      k=1;
   if(iOpen(NULL,0,1)<=UPBB1[0]  && iClose(NULL,0,1)>=UPBB1[0]  && Strategy_Type==1)
      k=-1;
   if(Bid<=DNBB1[0] && Strategy_Type==0)
      k=-1;   
   if(Bid<=DNBB1[0] && Strategy_Type==1)
      k=1;     
   if(iOpen(NULL,0,1)>=DNBB1[0]  && iClose(NULL,0,1)<=DNBB1[0]  && Strategy_Type==0)
      k=-1;
   if(iOpen(NULL,0,1)>=DNBB1[0]  && iClose(NULL,0,1)<=DNBB1[0]  && Strategy_Type==1)
      k=1;
   return(k);
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
void close(int TT)
{

//---

   for(int i=0; i<PositionsTotal()+1; i++)
   {
      if(PositionGetTicket(i)){
         if(PositionGetString(POSITION_SYMBOL)==Symbol() && PositionGetInteger(POSITION_MAGIC)==magic_num && PositionGetInteger(POSITION_TYPE)==TT)
            trade.PositionClose(PositionGetTicket(i));
      }
      
   }
   if(TT == POSITION_TYPE_BUY)
      Refresh_Buy();
   else if(TT == POSITION_TYPE_SELL)
      Refresh_Sell();   

//---
}
void CloseAllPositions(void)
  {
   for(int i=PositionsTotal()-1; i>=0; i--) // returns the number of current positions
      if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
         if(m_position.Magic()==magic_num)
            if(!trade.PositionClose(m_position.Ticket())){ // close a position by the specified m_symbol
               Print(__FILE__," ",__FUNCTION__,", ERROR: "," PositionClose ",m_position.Ticket(),", ",trade.ResultRetcodeDescription());
            }
            else{
               Refresh_Buy();
               Refresh_Sell();
            }   
  }
void CloseAllPositions(int op)
  {
   for(int i=PositionsTotal()-1; i>=0; i--) // returns the number of current positions
      if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
         if(m_position.Magic()==magic_num && m_position.PositionType() == (ENUM_POSITION_TYPE)op)
            if(!trade.PositionClose(m_position.Ticket())){ // close a position by the specified m_symbol
               Print(__FILE__," ",__FUNCTION__,", ERROR: "," PositionClose ",m_position.Ticket(),", ",trade.ResultRetcodeDescription());
            }
            else{
               Refresh_Buy();
               Refresh_Sell();
            }   
  }  
void CloseAll()
{
   for(int i=0; i<PositionsTotal()+1; i++)
   {
      if(PositionGetTicket(i)){
         if(PositionGetString(POSITION_SYMBOL)==Symbol() && PositionGetInteger(POSITION_MAGIC)==magic_num )
            trade.PositionClose(PositionGetTicket(i));
      }
   }
   Refresh_Buy();
   Refresh_Sell();
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void MannualEntry(int op)
{
   double tpb = 0.0, tps = 0.0, slb =0.0, sls =0.0;
   if(UsePointStop){
      tpb = SymbolInfoDouble(Symbol(),SYMBOL_ASK)+TP_Point*Point();
      slb = SymbolInfoDouble(Symbol(),SYMBOL_ASK)-SL_Point*Point();
      tps = SymbolInfoDouble(Symbol(),SYMBOL_BID)-TP_Point*Point();
      sls = SymbolInfoDouble(Symbol(),SYMBOL_BID)+SL_Point*Point();
   }
   else{
      tpb = 0;
      slb = 0;
      tps = 0;
      sls = 0;
   }
   if(op == ORDER_TYPE_BUY){
      if(OrdersTT(ORDER_TYPE_BUY)==0 && (Grid_Direction==Grid_Long||Grid_Direction==Grid_Both))
         if(trade.Buy(Lot_Size,NULL,SymbolInfoDouble(Symbol(),SYMBOL_ASK),slb,tpb,Trade_Comment)){  
            C_B_N=0;
            GB_N[C_B_N]=SymbolInfoDouble(Symbol(),SYMBOL_ASK);
            GBL_N[C_B_N]=Lot_Size;
            C_B_P=0;
            GB_P[C_B_P]=SymbolInfoDouble(Symbol(),SYMBOL_ASK);
            GBL_P[C_B_P]=Lot_Size;
            OPB=SymbolInfoDouble(Symbol(),SYMBOL_ASK)+OPB;
            Count_B++;
            FTPB=tpb;   
         }
   }
   
   else if(op == ORDER_TYPE_SELL && (Grid_Direction==Grid_Short||Grid_Direction==Grid_Both)){
      if(OrdersTT(ORDER_TYPE_SELL)==0)
         if(trade.Sell(Lot_Size,NULL,SymbolInfoDouble(Symbol(),SYMBOL_BID),sls,tps,Trade_Comment)){    
            C_S_N=0;
            GS_N[C_S_N]=SymbolInfoDouble(Symbol(),SYMBOL_BID);
            GSL_N[C_S_N]=Lot_Size;
            C_S_P=0;
            GS_P[C_S_P]=SymbolInfoDouble(Symbol(),SYMBOL_BID);
            GSL_P[C_S_P]=Lot_Size;
            OPS=SymbolInfoDouble(Symbol(),SYMBOL_BID)+OPS;
            Count_S++;
            FTPS=tps;
         }
   }

}
int Orders( )
{

//---
   int k=0;

   for(int i=PositionsTotal()-1; i>=0; i--)
   {
      if(PositionGetTicket(i))
      {
         if(PositionGetString(POSITION_SYMBOL)==Symbol() && PositionGetInteger(POSITION_MAGIC)==magic_num)
            k++;
      }

   }
   return(k);


}
//+------------------------------------------------------------------+
int OrdersTT( int TT)
{

//---
   int k=0;

   for(int i=PositionsTotal()-1; i>=0; i--)
   {
      if(PositionGetTicket(i))
      {
         if(PositionGetString(POSITION_SYMBOL)==Symbol() && PositionGetInteger(POSITION_TYPE)==TT && PositionGetInteger(POSITION_MAGIC)==magic_num)
            k++;
      }

   }
   return(k);


}
int OrdersTTUpdated( int TT)
{

//---
   int k=0;

   for(int i=PositionsTotal()-1; i>=0; i--)
   {
      if(m_position.SelectByIndex(i))
      {
         if(m_position.Symbol()==Symbol() && m_position.Magic()==magic_num && m_position.PositionType()==TT )
            k++;
      }

   }
   return(k);


}
double LastOrderPrice(int op)
{
   datetime time =D'01.01.2020';
      double k = 0.0;
      for(int i=0; i<PositionsTotal(); i++)
      {
         if(PositionGetTicket(i))
         {
            if(PositionGetString(POSITION_SYMBOL)==Symbol() && PositionGetInteger(POSITION_TYPE)==op && PositionGetInteger(POSITION_MAGIC)==magic_num)
             {
               if(PositionGetInteger(POSITION_TIME)>= time)
               {
                  time =(datetime) PositionGetInteger(POSITION_TIME);
                  k = PositionGetDouble(POSITION_PRICE_OPEN);
               }  
             }
         }

      }
      return k;
   

}
double LastOrderPrice(int op, double &lots)
{
   datetime time =D'01.01.2020';
      double k = 0.0;
      for(int i=0; i<PositionsTotal(); i++)
      {
         if(PositionGetTicket(i))
         {
            if(PositionGetString(POSITION_SYMBOL)==Symbol() && PositionGetInteger(POSITION_TYPE)==op && PositionGetInteger(POSITION_MAGIC)==magic_num)
             {
               if(PositionGetInteger(POSITION_TIME)>= time)
               {
                  time =(datetime) PositionGetInteger(POSITION_TIME);
                  k = PositionGetDouble(POSITION_PRICE_OPEN);
                  lots = PositionGetDouble(POSITION_VOLUME);
               }  
             }
         }

      }
      return k;
   

}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetPnl(){
   double  num=0;
   for(int i=PositionsTotal()-1; i>=0; i--)
   {
      if(PositionGetTicket(i))
      {
         if(PositionGetInteger(POSITION_MAGIC)==magic_num && PositionGetString(POSITION_SYMBOL)==Symbol())
            num=num+PositionGetDouble(POSITION_PROFIT);
      }
   }
   return num;
}
double GetPnl(int op){
   double  num=0;
   for(int i=PositionsTotal()-1; i>=0; i--)
   {
      if(PositionGetTicket(i))
      {
         if(PositionGetInteger(POSITION_MAGIC)==magic_num && PositionGetString(POSITION_SYMBOL)==Symbol() && PositionGetInteger(POSITION_TYPE)== op)
            num=num+PositionGetDouble(POSITION_PROFIT);
      }
   }
   return num;
}
void CheckLoss()
{
   double  num=0;
   for(int i=PositionsTotal()-1; i>=0; i--)
   {
      if(PositionGetTicket(i))
      {
         if(PositionGetInteger(POSITION_MAGIC)==magic_num && PositionGetString(POSITION_SYMBOL)==Symbol())
            num=num+PositionGetDouble(POSITION_PROFIT);
      }
   }
   if(num<SL_Money*(-1) || num>=TP_Money)
   {
      Refresh_Buy();
      Refresh_Sell();
      CloseAllPositions();
      C_B_P=-1;
      C_S_P=-1;
      C_B_N=-1;
      C_S_N=-1;
   }


}
//+------------------------------------------------------------------+
void Average_SL(double NSL )
{


   for(int i=0; i<PositionsTotal(); i++)
   {
      if(PositionGetTicket(i))
      {
         if(PositionGetInteger(POSITION_MAGIC)==magic_num && PositionGetString(POSITION_SYMBOL)==Symbol() && PositionGetDouble(POSITION_SL)!=NSL )
         trade.PositionModify(PositionGetTicket(i),NSL,PositionGetDouble(POSITION_TP));
          //  int yy=OrderModify(OrderTicket(),OrderOpenPrice(),NSL,OrderTakeProfit(), 0, clrNONE);
      }
   }
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Refresh_Buy()
{
   ArrayFill(GB_N,0,1000,0);
   ArrayFill(GBL_N,0,1000,0);
   C_B_N=-1;
//*********
   ArrayFill(GB_P,0,1000,0);
   ArrayFill(GBL_P,0,1000,0);
   C_B_P=-1;


}
//+------------------------------------------------------------------+
void Refresh_Sell()
{
   ArrayFill(GS_P,0,1000,0);
   ArrayFill(GSL_P,0,1000,0);
   C_S_P=-1;
//**********************
   ArrayFill(GS_N,0,1000,0);
   ArrayFill(GSL_N,0,1000,0);
   C_S_N=-1;


}
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
bool trail_flag = false;
double trail_equity =0.0;
void EquityTrail(bool use, double start, double width){
   if(!use)return;
   
   double pnl = GetPnl();
   
   //trail 
   if(trail_flag){
      if(pnl<=trail_equity){
         //Liquidate
         trail_flag = false;
         Alert("Liquidating positions- Equity trail- Profit["+DoubleToString(pnl,2)+"] trail["+DoubleToString(trail_equity,2)+"]");
         if(Grid_Direction == Grid_Long)
            CloseAllPositions(POSITION_TYPE_BUY);
         else if(Grid_Direction == Grid_Short)
            CloseAllPositions(POSITION_TYPE_SELL); 
         else if(Grid_Direction == Grid_Both)
            CloseAllPositions();  
         return;
      }
      else if((pnl-trail_equity)> width){
         trail_equity = pnl-width;
      }
   }
   else if(!trail_flag){
      if(pnl >= start){
         
         trail_flag = true;
         trail_equity = pnl-width;
         Print("Trail Started-"+Symbol()+"- Trailing at: "+DoubleToString(trail_equity,1));
         return;
      }
   }

}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
