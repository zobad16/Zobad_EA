//+------------------------------------------------------------------+
//|                                          YickEnhancedStealth.mq4 |
//|							               Version: 1.1 Updated 20130909 |
//|                                       Copyright 2013, GoldlandFX |
//|                                        http://www.goldlandfx.com |
//|                                     Contact: info@goldlandfx.com |
//|                                                 Author: Yick Tan |
//+------------------------------------------------------------------+
#property copyright "YES-TM EA.mq4 Copyright 2013, GoldlandFX."
#property link      "http://www.goldlandfx.com"

extern   int      MagicNumber = 0;//168169;
extern   int      NumberofRetry = 3;
extern   double   OrderHiddenTP = 90; //In Point, 5 Digit Broker
extern   double   OrderHiddenSL = 90; //In Point, 5 Digit Broker
extern   double   OrderTS1 = 20; //In Point, 5 Digit Broker
extern   double   OrderTS1Trigger = 50; //In Point, 5 Digit Broker
extern   double   OrderTS2 = 50; //In Point, 5 Digit Broker
extern   double   OrderTS2Trigger = 100; //In Point, 5 Digit Broker
extern   double   OrderTS3 = 100; //In Point, 5 Digit Broker
extern   double   OrderTS3Trigger = 200; //In Point, 5 Digit Broker
extern   double   OrderTS4 = 200; //In Point, 5 Digit Broker
extern   double   OrderTS4Trigger = 400; //In Point, 5 Digit Broker
extern   bool     OrderTS5Jump = FALSE;
extern   bool     BreakEven = FALSE;
extern   int      BreakEvenTime = 900;//Time Unit Seconds
extern   double   BreakEvenTP = 20;//In Point, 5 Digit Broker

double   OrderArray[][14], bid, ask, point;
int      i, j, icnt, jcnt, t, OrderTickets, OrderArrayIdx, FoundZeroIdx, OrderLongShort;
int      TotalNumberOfOrders, TempNumberOfOrders, CountNumberOfOrders;
int      OrderProfitPip, OrderLossPip, Slippage=15;
bool     TradeFound, OrderFound = FALSE, FoundZero=FALSE, OrderCloseStatus;
//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
  {
//----
   TotalNumberOfOrders = OrdersTotal();
   ArrayResize(OrderArray, TotalNumberOfOrders);
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+
int deinit()
  {
//----
   
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start()
  {
//----
   if (TotalNumberOfOrders < OrdersTotal()) {
      TotalNumberOfOrders = OrdersTotal();
      ArrayResize(OrderArray, TotalNumberOfOrders);
      Print ("OrderArray Size Increased to: "+TotalNumberOfOrders);
   }
   
   if (TotalNumberOfOrders > OrdersTotal()) {
      //Eliminate Manually Closed Trade, Other EA/Script Closed trade or Trade that hits MT4 System TP/SL
      TempNumberOfOrders = OrdersTotal();
      CountNumberOfOrders = TempNumberOfOrders;
      for (icnt=TotalNumberOfOrders-1; icnt>=0; icnt--) {
         TradeFound = FALSE;
         for (jcnt=TempNumberOfOrders-1; jcnt>=0; jcnt--) {
            if (OrderSelect(jcnt, SELECT_BY_POS, MODE_TRADES)) {
               if (OrderArray[icnt][0]==OrderTicket()) {
                  TradeFound = TRUE;
                  break;
               }
            }
         }

         if (!TradeFound) {
            //Print ("Closed:"+OrderArray[icnt][0]);
            ResetOrderArray(icnt);
            PurgeElement(icnt);
            CountNumberOfOrders = TotalNumberOfOrders - 1;
            ArrayResize(OrderArray, CountNumberOfOrders);
            if (CountNumberOfOrders==TempNumberOfOrders) break;
         }
      }
      TotalNumberOfOrders = CountNumberOfOrders;
      Print ("OrderArray Size Decreased to: "+TotalNumberOfOrders);
   }
   
   for (i=TotalNumberOfOrders-1; i>=0; i--) {

      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
         Print (i+"/"+TotalNumberOfOrders+">>"+OrderSymbol()+">>"+OrderTicket()+">>"+TotalNumberOfOrders);
         if (OrderMagicNumber()==MagicNumber) {
         FoundZero = FALSE;
         OrderFound = FALSE;
         
         for (j=TotalNumberOfOrders-1; j>=0; j--) {
            Print ("After reset:"+j+">>"+OrderArray[j][0]);
            if (OrderArray[j][0]==OrderTicket()) {
               OrderFound = TRUE;
               OrderArrayIdx = j;
               break;
            }
            if ((OrderArray[j][0]==0) && (!FoundZero) && (!OrderFound)) {
               FoundZero = TRUE;
               FoundZeroIdx = j;
            }
         }
         Print ("OrderFound:"+OrderFound+">> FoundZero:"+FoundZero+">> TotalNumberOfOrders:"+(TotalNumberOfOrders-1)+">>"+i);
         
         if (!OrderFound && FoundZero) {
            OrderArray[FoundZeroIdx][0] = OrderTicket();
            OrderArray[FoundZeroIdx][1] = OrderMagicNumber();
            OrderArray[FoundZeroIdx][2] = OrderType();
            OrderArray[FoundZeroIdx][3] = OrderLots();
            OrderArray[FoundZeroIdx][4] = OrderOpenTime();
            OrderArray[FoundZeroIdx][5] = OrderOpenPrice();
            OrderArray[FoundZeroIdx][6] = OrderCommission();
            OrderArray[FoundZeroIdx][7] = OrderTakeProfit();
            OrderArray[FoundZeroIdx][8] = OrderStopLoss();
            OrderArray[FoundZeroIdx][9] = 0; //TS1
            OrderArray[FoundZeroIdx][10] = 0; //TS2
            OrderArray[FoundZeroIdx][11] = 0; //TS3
            OrderArray[FoundZeroIdx][12] = 0; //TS4
            OrderArray[FoundZeroIdx][13] = 0; //TS5
            FoundZero = FALSE;
         } else {
            //Found the Order
            OrderLongShort = OrderArray[OrderArrayIdx][2];
            //Print ("OrderLongShort: "+OrderLongShort);
            bid = MarketInfo(OrderSymbol(),MODE_BID);
            ask = MarketInfo(OrderSymbol(),MODE_ASK);
            point = MarketInfo(OrderSymbol(),MODE_POINT);
            
            if (OrderLongShort == OP_BUY) {
               OrderProfitPip = (bid - OrderArray[OrderArrayIdx][5])/point;
               OrderLossPip = (OrderArray[OrderArrayIdx][5] - bid)/point;
               //Print (OrderSymbol()+">>"+OrderArray[OrderArrayIdx][0]+">>"+OrderArray[OrderArrayIdx][8]+">>"+bid+">>"+ask+">>"+OrderLossPip+">>"+OrderHiddenSL);

               //Print ("Trailing1L: "+OrderTicket()+">>"+OrderProfitPip+">>"+OrderTS1Trigger+">>"+OrderArray[OrderArrayIdx][9]);
               if ((OrderArray[OrderArrayIdx][9]==0) && (OrderProfitPip>OrderTS1Trigger)) {
                  Print ("Long Trailing Stop1 Activated at: "+(OrderOpenPrice()+(OrderTS1*point)));
                  OrderArray[OrderArrayIdx][9] = (OrderOpenPrice()+(OrderTS1*point));
               }

               //Print ("Trailing2L: "+OrderTicket()+">>"+OrderProfitPip+">>"+OrderTS2Trigger+">>"+OrderArray[OrderArrayIdx][10]);
               if ((OrderArray[OrderArrayIdx][9]!=0) && (OrderArray[OrderArrayIdx][10]==0) && (OrderProfitPip>OrderTS2Trigger)) {
                  Print ("Long Trailing Stop2 Activated at: "+(OrderOpenPrice()+(OrderTS2*point)));
                  OrderArray[OrderArrayIdx][10] = (OrderOpenPrice()+(OrderTS2*point));
               }

               //Print ("Trailing3L: "+OrderTicket()+">>"+OrderProfitPip+">>"+OrderTS3Trigger+">>"+OrderArray[OrderArrayIdx][11]);
               if ((OrderArray[OrderArrayIdx][9]!=0) && (OrderArray[OrderArrayIdx][10]!=0) && 
               (OrderArray[OrderArrayIdx][11]==0) && (OrderProfitPip>OrderTS3Trigger)) {
                  Print ("Long Trailing Stop3 Activated at: "+(OrderOpenPrice()+(OrderTS3*point)));
                  OrderArray[OrderArrayIdx][11] = (OrderOpenPrice()+(OrderTS3*point));
               }

               //First time TS4
               //Print ("Trailing4L: "+OrderTicket()+">>"+OrderProfitPip+">>"+OrderTS4Trigger+">>"+OrderArray[OrderArrayIdx][12]);
               if ((OrderArray[OrderArrayIdx][9]!=0) && (OrderArray[OrderArrayIdx][10]!=0) && 
               (OrderArray[OrderArrayIdx][11]!=0) && (OrderArray[OrderArrayIdx][12]==0) && (OrderProfitPip>OrderTS4Trigger)) {
                  Print ("Long Trailing Stop4 Activated at: "+(OrderOpenPrice()+(OrderTS4*point)));
                  OrderArray[OrderArrayIdx][12] = (OrderOpenPrice()+(OrderTS4*point));
                  OrderArray[OrderArrayIdx][13] = (OrderOpenPrice()+(OrderTS4*point));
               }

               //TS5 - Price Trailing
               //Print ("Trailing5L: "+OrderTicket()+">>"+OrderProfitPip+">>"+OrderTS4Trigger+">>"+OrderArray[OrderArrayIdx][13]);
               if ((OrderArray[OrderArrayIdx][9]!=0) && (OrderArray[OrderArrayIdx][10]!=0) && 
               (OrderArray[OrderArrayIdx][11]!=0) && (OrderArray[OrderArrayIdx][12]!=0) && 
               ((bid+(OrderTS4*point))>OrderArray[OrderArrayIdx][13]) && !OrderTS5Jump) {
                  Print ("Long Trigger Trailing Stop5 Activated at: "+(OrderArray[OrderArrayIdx][13]+(OrderTS4*point)));
                  OrderArray[OrderArrayIdx][13] = (bid-(OrderTS4*point));
               }

               //TS5 - Jump Trailing
               //Print ("Trailing5LJ: "+OrderTicket()+">>"+OrderProfitPip+">>"+OrderTS4Trigger+">>"+OrderArray[OrderArrayIdx][13]);
               if ((OrderArray[OrderArrayIdx][9]!=0) && (OrderArray[OrderArrayIdx][10]!=0) && 
               (OrderArray[OrderArrayIdx][11]!=0) && (OrderArray[OrderArrayIdx][12]!=0) && 
               ((bid+(2*OrderTS4*point))>OrderArray[OrderArrayIdx][13]) && OrderTS5Jump) {
                  Print ("Long Trigger Trailing Stop5 Activated at: "+(OrderArray[OrderArrayIdx][13]+(OrderTS4*point)));
                  OrderArray[OrderArrayIdx][13] = (OrderArray[OrderArrayIdx][13]+(OrderTS4*point));
               }

               //Long Order Processing
               if (OrderProfitPip>=OrderHiddenTP) {
                  Print ("Take Long Profit Now: "+OrderProfitPip);
                  //Close and Set zero of the orderarray item
                  for (t=0; t<NumberofRetry; t++) {
                     OrderCloseStatus = OrderClose(OrderTicket(), OrderLots(), bid, Slippage, Blue);
                     if (OrderCloseStatus) {
                        ResetOrderArray (OrderArrayIdx);
                        PurgeElement(OrderArrayIdx);
                        break;
                     }
                  }
               }

               if (OrderLossPip>=OrderHiddenSL) {
                  Print ("Stop Long Loss Now: "+OrderLossPip);
                  //Close and Set zero of the orderarray item
                  for (t=0; t<NumberofRetry; t++) {
                     OrderCloseStatus = OrderClose(OrderTicket(), OrderLots(), bid, Slippage, DeepSkyBlue);
                     if (OrderCloseStatus) {
                        ResetOrderArray (OrderArrayIdx);
                        PurgeElement(OrderArrayIdx);
                        break;
                     }
                  }
               }

               if (((OrderArray[OrderArrayIdx][9]!=0) && (bid < OrderArray[OrderArrayIdx][9])) ||
               ((OrderArray[OrderArrayIdx][10]!=0) && (bid < OrderArray[OrderArrayIdx][10])) ||
               ((OrderArray[OrderArrayIdx][11]!=0) && (bid < OrderArray[OrderArrayIdx][11])) ||
               ((OrderArray[OrderArrayIdx][12]!=0) && (bid < OrderArray[OrderArrayIdx][12])) ||
               ((OrderArray[OrderArrayIdx][13]!=0) && (bid < OrderArray[OrderArrayIdx][13]))) {
                  Print("Long:"+OrderTicket()+". Trailing Stop Triggerred. Order Closed at: "+bid);
                  //Close and Set zero of the orderarray item
                  for (t=0; t<NumberofRetry; t++) {
                     OrderCloseStatus = OrderClose(OrderTicket(), OrderLots(), bid, Slippage, DeepSkyBlue);
                     if (OrderCloseStatus) {
                        ResetOrderArray (OrderArrayIdx);
                        PurgeElement(OrderArrayIdx);
                        break;
                     }
                  }
               }
               
               if (BreakEven && (TimeCurrent() > (OrderArray[OrderArrayIdx][4]+BreakEvenTime)) && 
               (bid > (OrderArray[OrderArrayIdx][5]+(OrderTS4*point)))) {
                  Print("LongBE:"+OrderTicket()+". Breakeven Triggerred. Order Closed at: "+bid);
                  //Close and Set zero of the orderarray item
                  for (t=0; t<NumberofRetry; t++) {
                     OrderCloseStatus = OrderClose(OrderTicket(), OrderLots(), bid, Slippage, Navy);
                     if (OrderCloseStatus) {
                        ResetOrderArray (OrderArrayIdx);
                        PurgeElement(OrderArrayIdx);
                        break;
                     }
                  }
               }
            }

            if (OrderLongShort == OP_SELL) {
               OrderProfitPip = (OrderArray[OrderArrayIdx][5] - ask)/point;
               OrderLossPip = (ask - OrderArray[OrderArrayIdx][5])/point;
               Print (OrderSymbol()+">>"+OrderArray[OrderArrayIdx][0]+">>"+OrderArray[OrderArrayIdx][8]+">>"+bid+">>"+ask+">>"+OrderLossPip+">>"+OrderHiddenSL);

               //Print ("Trailing1S: "+OrderTicket()+">>"+OrderProfitPip+">>"+OrderTS1Trigger+">>"+OrderArray[OrderArrayIdx][9]);
               if ((OrderArray[OrderArrayIdx][9]==0) && (OrderProfitPip>OrderTS1Trigger)) {
                  Print ("Short Trailing Stop1 Activated at: "+(OrderOpenPrice()-(OrderTS1*point)));
                  OrderArray[OrderArrayIdx][9] = (OrderOpenPrice()-(OrderTS1*point));
               }
               
               //Print ("Trailing2S: "+OrderTicket()+">>"+OrderProfitPip+">>"+OrderTS2Trigger+">>"+OrderArray[OrderArrayIdx][10]);
               if ((OrderArray[OrderArrayIdx][9]!=0) && (OrderArray[OrderArrayIdx][10]==0) && (OrderProfitPip>OrderTS2Trigger)) {
                  Print ("Short Trailing Stop2 Activated at: "+(OrderOpenPrice()-(OrderTS2*point)));
                  OrderArray[OrderArrayIdx][10] = (OrderOpenPrice()-(OrderTS2*point));
               }

               //Print ("Trailing3S: "+OrderTicket()+">>"+OrderProfitPip+">>"+OrderTS3Trigger+">>"+OrderArray[OrderArrayIdx][11]);
               if ((OrderArray[OrderArrayIdx][9]!=0) && (OrderArray[OrderArrayIdx][10]!=0) && 
               (OrderArray[OrderArrayIdx][11]==0) && (OrderProfitPip>OrderTS3Trigger)) {
                  Print ("Short Trailing Stop3 Activated at: "+(OrderOpenPrice()-(OrderTS3*point)));
                  OrderArray[OrderArrayIdx][11] = (OrderOpenPrice()-(OrderTS3*point));
               }

               //First time TS4
               //Print ("Trailing4S: "+OrderTicket()+">>"+OrderProfitPip+">>"+OrderTS4Trigger+">>"+OrderArray[OrderArrayIdx][12]);
               if ((OrderArray[OrderArrayIdx][9]!=0) && (OrderArray[OrderArrayIdx][10]!=0) && 
               (OrderArray[OrderArrayIdx][11]!=0) && (OrderArray[OrderArrayIdx][12]==0) && (OrderProfitPip>OrderTS4Trigger)) {
                  Print ("Short Trailing Stop4 Activated at: "+(OrderOpenPrice()-(OrderTS4*point)));
                  OrderArray[OrderArrayIdx][12] = (OrderOpenPrice()-(OrderTS4*point));
                  OrderArray[OrderArrayIdx][13] = (OrderOpenPrice()-(OrderTS4*point));
               }

               //TS5 - Price Trailing
               //Print ("Trailing5S: "+OrderTicket()+">>"+OrderProfitPip+">>"+OrderTS4Trigger+">>"+OrderArray[OrderArrayIdx][13]);
               if ((OrderArray[OrderArrayIdx][9]!=0) && (OrderArray[OrderArrayIdx][10]!=0) && 
               (OrderArray[OrderArrayIdx][11]!=0) && (OrderArray[OrderArrayIdx][12]!=0) && 
               ((ask-(OrderTS4*point))<OrderArray[OrderArrayIdx][13])  && !OrderTS5Jump) {
                  Print ("Short Trigger Trailing Stop5 Activated at: "+(OrderArray[OrderArrayIdx][13]-(OrderTS4*point)));
                  OrderArray[OrderArrayIdx][13] = (ask+(OrderTS4*point));
               }

               //TS5 - Jump Trailing
               //Print ("Trailing5JS: "+OrderTicket()+">>"+OrderProfitPip+">>"+OrderTS4Trigger+">>"+OrderArray[OrderArrayIdx][13]);
               if ((OrderArray[OrderArrayIdx][9]!=0) && (OrderArray[OrderArrayIdx][10]!=0) && 
               (OrderArray[OrderArrayIdx][11]!=0) && (OrderArray[OrderArrayIdx][12]!=0) && 
               ((ask-(2*OrderTS4*point))<OrderArray[OrderArrayIdx][13]) && OrderTS5Jump) {
                  Print ("Short Trigger Trailing Stop5 Activated at: "+(OrderArray[OrderArrayIdx][13]-(OrderTS4*point)));
                  OrderArray[OrderArrayIdx][13] = (OrderArray[OrderArrayIdx][13]-(OrderTS4*point));
               }

               //Short Order Processing
               if (OrderProfitPip>=OrderHiddenTP) {
                  Print ("Take Short Profit Now: "+OrderProfitPip);
                  //Close and Set zero of the orderarray item
                  for (t=0; t<NumberofRetry; t++) {
                     OrderCloseStatus = OrderClose(OrderTicket(), OrderLots(), ask, Slippage, Red);
                     if (OrderCloseStatus) {
                        ResetOrderArray (OrderArrayIdx);
                        PurgeElement(OrderArrayIdx);
                        break;
                     }
                  }
               }

               if (OrderLossPip>=OrderHiddenSL) {
                  Print ("Stop Short Loss Now: "+OrderLossPip);
                  //Close and Set zero of the orderarray item
                  for (t=0; t<NumberofRetry; t++) {
                     OrderCloseStatus = OrderClose(OrderTicket(), OrderLots(), ask, Slippage, DarkOrange);
                     if (OrderCloseStatus) {
                        ResetOrderArray (OrderArrayIdx);
                        PurgeElement(OrderArrayIdx);
                        break;
                     }
                  }
               }

               if (((OrderArray[OrderArrayIdx][9]!=0) && (ask > OrderArray[OrderArrayIdx][9])) ||
               ((OrderArray[OrderArrayIdx][10]!=0) && (ask > OrderArray[OrderArrayIdx][10])) ||
               ((OrderArray[OrderArrayIdx][11]!=0) && (ask > OrderArray[OrderArrayIdx][11])) ||
               ((OrderArray[OrderArrayIdx][12]!=0) && (ask > OrderArray[OrderArrayIdx][12])) ||
               ((OrderArray[OrderArrayIdx][13]!=0) && (ask > OrderArray[OrderArrayIdx][13]))) {
                  Print("Short:"+OrderTicket()+". Trailing Stop Triggerred. Order Closed at: "+ask);
                  //Close and Set zero of the orderarray item
                  for (t=0; t<NumberofRetry; t++) {
                     OrderCloseStatus = OrderClose(OrderTicket(), OrderLots(), ask, Slippage, DarkOrange);
                     if (OrderCloseStatus) {
                        ResetOrderArray (OrderArrayIdx);
                        PurgeElement(OrderArrayIdx);
                        break;
                     }
                  }
               }

               if (BreakEven && (TimeCurrent() > (OrderArray[OrderArrayIdx][4]+BreakEvenTime)) && 
               (ask < (OrderArray[OrderArrayIdx][5]+(OrderTS4*point)))) {
                  Print("LongBE:"+OrderTicket()+". Breakeven Triggerred. Order Closed at: "+ask);
                  //Close and Set zero of the orderarray item
                  for (t=0; t<NumberofRetry; t++) {
                     OrderCloseStatus = OrderClose(OrderTicket(), OrderLots(), ask, Slippage, Maroon);
                     if (OrderCloseStatus) {
                        ResetOrderArray (OrderArrayIdx);
                        PurgeElement(OrderArrayIdx);
                        break;
                     }
                  }
               }
            }
         }
         }//Magic Number
      Print ("==================================");
      }//Order Select
   }//For Loop
   
//----
   return(0);
  }
//+------------------------------------------------------------------+

void ResetOrderArray (int idx) {
   //Print ("Set0: "+OrderArray[idx][0]);
   for (int k=0; k<15; k++) {
      OrderArray[idx][k] = 0;
   }
}

int PurgeElement(int pidx) {
   int asize = (ArraySize(OrderArray)/14);
   int x = asize-1, y, z;
   double temparr[][14];

   Print ("ASize before purging: "+asize);

   if (OrderArray[pidx][0]==0) {

      //for (y=x; y>=0; y--) { Print(y+" ONum:"+OrderArray[y][0]); }
      
      ArrayResize(temparr, x);
      for (y=0; y<pidx; y++) {
         for (z=0; z<14; z++) { //Change to 14
            temparr[y][z] = OrderArray[y][z];
         }
         //Print ("1st:"+y+">>"+temparr[y][0]);
      }
   
      for (y=pidx+1; y<asize; y++) {
         for (z=0; z<14; z++) { //Change to 14
            temparr[(y-1)][z] = OrderArray[y][z];
         }
         //Print ("2nd:"+(y-1)+">>"+temparr[(y-1)][0]);
      }

     ArrayResize(OrderArray, x);
      for (y=0; y<x; y++) {
         for (z=0; z<14; z++) { //Change to 14
            OrderArray[y][z] = temparr[y][z];
         }
         //Print ("last:"+y+">>"+OrderArray[y][0]);
      }

     return (x);
  }
}