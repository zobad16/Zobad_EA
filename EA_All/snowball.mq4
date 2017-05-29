//+------------------------------------------------------------------+
//|                                   Copyright © 2010, Bernd Kreuss |
//|                        PayPal donations go here -> 7bit@arcor.de |
//+------------------------------------------------------------------+
#property copyright "© Bernd Kreuss, Version 2010.6.11.1"
#property link      "http://sites.google.com/site/prof7bit/"

#include <common_functions.mqh>
#include <offline_charts.mqh> 
//#include <oanda.mqh> 

extern double lots = 0.01; // lots to use per trade
//extern double oanda_factor = 25000;
extern int stop_distance = 20;
extern int auto_tp = 2; // auto-takeprofit this many levels (roughly) above the BE point
extern bool is_ecn_broker = false; // different market order procedure when resuming after pause

extern color clr_breakeven_level = Lime;
extern color clr_buy = Blue;
extern color clr_sell = Red;
extern color clr_gridline = Lime;
extern color clr_stopline_active = Magenta;
extern color clr_stopline_triggered = Aqua;
extern string sound_grid_trail = "";
extern string sound_grid_step = "";
extern string sound_order_triggered = "";
extern string sound_stop_all = "";

string name = "snow";

double pip;
double points_per_pip;
string comment;
int magic;
bool running;
int direction;
double last_line;
int level; // current level, signed, minus=short, calculated in trade()
double realized; // total realized (all time) (calculated in info())
double cycle_total_profit; // total profit since cycle started (calculated in info())
double stop_value; // dollars (account) per single level (calculated in info())
double auto_tp_price; // the price where auto_tp should trigger, calculated during break even calc.
double auto_tp_profit; // rough estimation of auto_tp profit, calculated during break even calc.

#define SP "                                    "

// trading direction
#define BIDIR 0
#define LONG  1
#define SHORT 2


void defaults(){
   /*
   IS_ECN_BROKER = true;
   //auto_tp = 2;
   
   if (IsTesting()){
      return(0);
   }
   if (Symbol6() == "GBPUSD"){
      lots = 0.1;
      oanda_factor = 900;
      stop_distance = 30;
   }
   if (Symbol6() == "EURUSD"){
      lots = 0.1;
      oanda_factor = 1800;
      stop_distance = 30;
   }
   if (Symbol6() == "USDCHF"){
      lots = 0.1;
      oanda_factor = 1800;
      stop_distance = 20;
   }
   if (Symbol6() == "USDJPY"){
      lots = 0.1;
      oanda_factor = 1800;
      stop_distance = 30;
   }
   
   sound_grid_step = "expert.wav";
   sound_grid_trail = "alert2.wav";
   sound_stop_all = "alert.wav";
   sound_order_triggered = "alert.wav";
   */
}


int init(){
   if (!IsDllsAllowed()){
      MessageBox("DLL imports must be allowed!", "Snowball");
      return(-1);
   }
      
   IS_ECN_BROKER = is_ecn_broker;
   CLR_BUY_ARROW = clr_buy;
   CLR_SELL_ARROW = clr_sell;
   CLR_CROSSLINE_ACTIVE = clr_stopline_active;
   CLR_CROSSLINE_TRIGGERED = clr_stopline_triggered;
   
   defaults();

   points_per_pip = pointsPerPip();
   pip = Point * points_per_pip;
   
   comment = name + "_" + Symbol6();
   magic = makeMagicNumber(name + "_" + Symbol());
   
   if (last_line == 0){
      last_line = getLine();
   }
   
   if (IsTesting()){
      setGlobal("realized", 0);
      setGlobal("running", 0);
   }
   
   readVariables();
   
   if (IsTesting() && !IsVisualMode()){
      Print("!!! This is not an automated strategy! Automated backtesting is nonsense! Starting in bidirectional mode!");
      running = true;
      direction = BIDIR;
      placeLine(Bid);
   }
      
   info();
}

int deinit(){
   deleteStartButtons();
   deleteStopButtons();
   storeVariables();
   if (UninitializeReason() == REASON_PARAMETERS){
      Comment("Parameters changed, pending orders deleted, will be replaced with the next tick");
      closeOpenOrders(OP_SELLSTOP, magic);
      closeOpenOrders(OP_BUYSTOP, magic);
   }else{
      Comment("EA removed, open orders, trades and status untouched!");
   }
}

void onTick(){
   recordEquity(name+Symbol6(), PERIOD_H1, magic);
   //checkOanda(magic, oanda_factor);
   checkLines();
   checkButtons();
   trade();
   info();
   checkAutoTP();
   if(!IsTesting()){
      plotNewOpenTrades(magic);
      plotNewClosedTrades(magic);
   }
}

void onOpen(){
}

void storeVariables(){
   setGlobal("running", running);
   setGlobal("direction", direction);
}

void readVariables(){
   running = getGlobal("running");
   direction = getGlobal("direction");
}

void deleteStartButtons(){
   ObjectDelete("start_long");
   ObjectDelete("start_short");
   ObjectDelete("start_bidir");
}

void deleteStopButtons(){
   ObjectDelete("stop");
   ObjectDelete("pause");
}

/**
* mark the start (or resume) of the cycle in the chart 
*/
void startArrow(){
   string aname = "cycle_start_" + TimeToStr(TimeCurrent());
   ObjectCreate(aname, OBJ_ARROW, 0, TimeCurrent(), Close[0]);
   ObjectSet(aname, OBJPROP_ARROWCODE, 5);
   ObjectSet(aname, OBJPROP_COLOR, clr_gridline);
   ObjectSet(aname, OBJPROP_BACK, true);
}

/**
* mark the end (or pause) of the cycle in the chart 
*/
void endArrow(){
   string aname = "cycle_end_" + TimeToStr(Time[0]);
   ObjectCreate(aname, OBJ_ARROW, 0, TimeCurrent(), Close[0]);
   ObjectSet(aname, OBJPROP_ARROWCODE, 6);
   ObjectSet(aname, OBJPROP_COLOR, clr_gridline);
   ObjectSet(aname, OBJPROP_BACK, true);
}

void stop(){
   endArrow();
   deleteStopButtons();
   closeOpenOrders(-1, magic);
   running = false;
   storeVariables();
   setGlobal("realized", getProfitRealized(magic)); // store this only on pyramid close
   //checkOanda(magic, oanda_factor);
   if (sound_stop_all != ""){
      PlaySound(sound_stop_all);
   }
}

void go(int mode){
   startArrow();
   deleteStartButtons();
   running = true;
   direction = mode;
   storeVariables();
   resume();
}

void pause(){
   endArrow();
   deleteStopButtons();
   label("paused_level", 15, 100, 1, level, Yellow);
   closeOpenOrders(-1, magic);
   running = false;
   storeVariables();
   //checkOanda(magic, oanda_factor);
   if (sound_stop_all != ""){
      PlaySound(sound_stop_all);
   }
}

/**
* resume trading after we paused it.
* Find the text label containing the level where we hit pause
* and re-open the corresponding amounts of lots, then delete the label.
*/ 
void resume(){
   int i;
   double sl;
   double line = getLine();
   level = StrToInteger(ObjectDescription("paused_level"));
   
   if (direction == LONG){
      level = MathAbs(level);
   }
   
   if (direction == SHORT){
      level = -MathAbs(level);
   }
   
   if (level > 0){
      for (i=1; i<=level; i++){
         sl = line - pip * i * stop_distance;
         buy(lots, sl, 0, magic, comment);
      }
   }
   
   if (level < 0){
      for (i=1; i<=-level; i++){
         sl = line + pip * i * stop_distance;
         sell(lots, sl, 0, magic, comment);
      }
   }
      
   ObjectDelete("paused_level");
}

void checkLines(){
   if (crossedLine("stop")){
      stop();
   }
   if (crossedLine("pause")){
      pause();
   }
   if (crossedLine("start long")){
      go(LONG);
   }
   if (crossedLine("start short")){
      go(SHORT);
   }
   if (crossedLine("start bidir")){
      go(BIDIR);
   }   
}

void checkButtons(){
   if(!running){
      deleteStopButtons();
      if (labelButton("start_long", 15, 15, 1, "start long", Lime)){
         go(LONG);
      }
      if (labelButton("start_short", 15, 30, 1, "start short", Lime)){
         go(SHORT);
      }
      if (labelButton("start_bidir", 15, 45, 1, "start bidirectional", Lime)){
         go(BIDIR);
      }
   }
   
   if (running){
      deleteStartButtons();
      if (labelButton("stop", 15, 15, 1, "stop", Red)){
         stop();
      }
      if (labelButton("pause", 15, 30, 1, "pause", Yellow)){
         pause();
      }
   }
}

void checkAutoTP(){
   if (auto_tp > 0 && auto_tp_price > 0){
      if (level > 0 && Close[0] >= auto_tp_price){
         stop();
      }
      if (level < 0 && Close[0] <= auto_tp_price){
         stop();
      }
   }
}

void placeLine(double price){
   horizLine("last_order", price, clr_gridline, SP + "grid position");
   last_line = price;
   WindowRedraw();
}

double getLine(){
   return(ObjectGet("last_order", OBJPROP_PRICE1));
}

bool lineMoved(){
   double line = getLine();
   if (line != last_line){
      // line has been moved by external forces (hello wb ;-)
      if (MathAbs(line - last_line) < stop_distance * pip){
         // minor adjustment by user
         last_line = line;
         return(true);
      }else{
         // something strange (gap? crash? line deleted?)
         if (MathAbs(Bid - last_line) < stop_distance * pip){
            // last_line variable still near price and thus is valid.
            placeLine(last_line); // simply replace line
            return(false); // no action needed
         }else{
            // line is far off or completely missing and last_line doesn't help also
            // make a completely new line at Bid
            placeLine(Bid);
            return(true);
         }
      }
      return(true);
   }else{
      return(false);
   }
}

/**
* manage all the entry order placement
*/
void trade(){
   double start;
   static int last_level;
   
   if (lineMoved()){
      closeOpenOrders(OP_SELLSTOP, magic);
      closeOpenOrders(OP_BUYSTOP, magic);
   }
   start = getLine();
   
   // calculate global variable level here // FIXME: global variable side-effect hell.
   level = getNumOpenOrders(OP_BUY, magic) - getNumOpenOrders(OP_SELL, magic);
   
   if (running){
      // are we flat?
      if (level == 0){
         if (direction == SHORT && Ask > start){
            if (getNumOpenOrders(OP_SELLSTOP, magic) != 2){
               closeOpenOrders(OP_SELLSTOP, magic);
            }else{
               moveOrders(Ask - start);
            }
            placeLine(Ask);
            start = Ask;
            plotBreakEven();
            if (sound_grid_trail != ""){
               PlaySound(sound_grid_trail);
            }
         }
         
         if (direction == LONG && Bid < start){
            if (getNumOpenOrders(OP_BUYSTOP, magic) != 2){
               closeOpenOrders(OP_BUYSTOP, magic);
            }else{
               moveOrders(Bid - start);
            }
            placeLine(Bid);
            start = Bid;
            plotBreakEven();
            if (sound_grid_trail != ""){
               PlaySound(sound_grid_trail);
            }
         }
         
         // make sure first long orders are in place
         if (direction == BIDIR || direction == LONG){
            longOrders(start);
         }
         
         // make sure first short orders are in place
         if (direction == BIDIR || direction == SHORT){
            shortOrders(start);
         }
      }
   
      // are we already long?
      if (level > 0){
         // make sure the next long orders are in place
         longOrders(start);
      }

      // are we short?
      if (level < 0){
         // make sure the next short orders are in place
         shortOrders(start);
      }
      
      // we have two different models how to move the grid line.
      // If we are *not* flat we can snap it to the nearest grid level,
      // ths is better for handling situations where the order is triggered 
      // by the exact pip and price is immediately reversing.
      // If we are currently flat we *must* move it only when we have reached 
      // it *exactly*, because otherwise this would badly interfere with 
      // the trailing of the grid in the unidirectional modes. Also in 
      // bidirectional mode this would have some unwanted effects.
      if (level != 0){
         // snap to grid
         if (Ask + (pip * stop_distance / 6) >= start + stop_distance*pip){
            jumpGrid(1);
         }
      
         // snap to grid
         if (Bid - (pip * stop_distance / 6) <= start - stop_distance*pip){
            jumpGrid(-1);
         }
      }else{   
         // grid reached exactly
         if (Ask  >= start + stop_distance*pip){
            jumpGrid(1);
         }
         
         // grid reached exactly
         if (Bid  <= start - stop_distance*pip){
            jumpGrid(-1);
         }
      }
      
      // alert on level change (order triggered, not line moved)
      if (level != last_level){
         if (sound_order_triggered != ""){
            PlaySound(sound_order_triggered);
         }
         last_level = level;
      }
      
   }else{ // not running
      placeLine(Bid);
   }
}

/**
* move the line 1 stop_didtance up or down.
* 1 means up, -1 means down.
*/
void jumpGrid(int dir){
   placeLine(getLine() + pip * stop_distance * dir);
   if (sound_grid_step != ""){
      PlaySound(sound_grid_step);
   }
}

/**
* do we need to place a new entry order at this price?
* This is done by looking for a stoploss below or above the price
* where=-1 searches for stoploss below, where=1 for stoploss above price
* return false if there is already an order (open or pending)
*/ 
bool needsOrder(double price, int where){
   //return(false);
   int i;
   int total = OrdersTotal();
   int type;
   // search for a stoploss at exactly one grid distance away from price
   for (i=0; i<total; i++){
      OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
      type = OrderType();
      if (where < 0){ // look only for buy orders (stop below)
         if (OrderMagicNumber() == magic && (type == OP_BUY || type == OP_BUYSTOP)){
            if (isEqualPrice(OrderStopLoss(), price + where * pip * stop_distance)){
               return(false);
            }
         }
      }
      if (where > 0){ // look only for sell orders (stop above)
         if (OrderMagicNumber() == magic && (type == OP_SELL || type == OP_SELLSTOP)){
            if (isEqualPrice(OrderStopLoss(), price + where * pip * stop_distance)){
               return(false);
            }
         }
      }
   }
   return(true);
}

/**
* Make sure there are the next two long orders above start in place.
* If they are already there do nothing, else replace the missing ones.
*/
void longOrders(double start){
   double a = start + stop_distance * pip;
   double b = start + 2 * stop_distance * pip;
   if (needsOrder(a, -1)){
      buyStop(lots, a, start, 0, magic, comment);
   }
   if (needsOrder(b, -1)){
      buyStop(lots, b, a, 0, magic, comment);
   }
}

/**
* Make sure there are the next two short orders below start in place.
* If they are already there do nothing, else replace the missing ones.
*/
void shortOrders(double start){
   double a = start - stop_distance * pip;
   double b = start - 2 * stop_distance * pip;
   if (needsOrder(a, 1)){
      sellStop(lots, a, start, 0, magic, comment);
   }
   if (needsOrder(b, 1)){
      sellStop(lots, b, a, 0, magic, comment);
   }
}

/**
* move all entry orders by the amount of d
*/
void moveOrders(double d){
   int i;
   for(i=0; i<OrdersTotal(); i++){
      OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
      if (OrderMagicNumber() == magic){
         if (MathAbs(OrderOpenPrice() - getLine()) > 3 * stop_distance * pip){
            orderDeleteReliable(OrderTicket());
         }else{
            orderModifyReliable(
               OrderTicket(),
               OrderOpenPrice() + d,
               OrderStopLoss() + d,
               0,
               0,
               CLR_NONE
            );
         }
      }
   }
}

void info(){
   double floating;
   double pb, lp, tp;
   static int last_ticket;
   static datetime last_be_plot = 0; 
   int ticket;
   string dir;
   
   OrderSelect(OrdersHistoryTotal()-1, SELECT_BY_POS, MODE_HISTORY);
   ticket = OrderTicket();
   
   if (ticket != last_ticket){
      // history changed, need to recalculate realized profit
      realized = getProfitRealized(magic);
      last_ticket = ticket;
      
      // enforce a new break-even arrow plot immediately
      last_be_plot = 0;
   }
   
   floating = getProfit(magic);
   
   // the variable realized is the total realized of all time. 
   // the MT4-global variable _realized is a snapshot of this value when 
   // the EA was reset the last time. The difference is what we made
   // during the current cycle. Add floating to it and we have the 
   // profit of the current cycle.
   cycle_total_profit = realized - getGlobal("realized") + floating;
   
   if (running == false){
      dir = "trading stopped";
   }else{
      switch(direction){
         case LONG: 
            dir = "trading long";
            break;
         case SHORT: 
            dir = "trading short";
            break;
         default: 
            dir = "trading both directions";
      }
   }
   
   int level_abs = MathAbs(getNumOpenOrders(OP_BUY, magic) - getNumOpenOrders(OP_SELL, magic));
   stop_value = MarketInfo(Symbol(), MODE_TICKVALUE) * lots * stop_distance * points_per_pip;
   
   Comment("\n" + SP + name + magic + ", " + dir +
           "\n" + SP + "1 pip is " + DoubleToStr(pip, Digits) + " " + Symbol6() +
           "\n" + SP + "stop distance: " + stop_distance + " pip, lot-size: " + DoubleToStr(lots, 2) +
           "\n" + SP + "every stop equals " + DoubleToStr(stop_value, 2) + " " + AccountCurrency() +
           "\n" + SP + "realized: " + DoubleToStr(realized - getGlobal("realized"), 2) + "  floating: " + DoubleToStr(floating, 2) +
           "\n" + SP + "profit: " + DoubleToStr(cycle_total_profit, 2) + " " + AccountCurrency() + "  current level: " + level_abs +
           "\n" + SP + "auto-tp: " + auto_tp + " levels (" + DoubleToStr(auto_tp_price, Digits) + ", " + DoubleToStr(auto_tp_profit, 2) + " " + AccountCurrency() + ")");

   if (last_be_plot == 0 || TimeCurrent() - last_be_plot > 300){ // every 5 minutes
      plotBreakEven();
      last_be_plot = TimeCurrent();
   }

   // If you put a text object (not a label!) with the name "profit",  
   // anywhere on the chart then this can be used as a profit calculator.
   // The following code will find the position of this text object 
   // and calculate your profit, should price reach this position
   // and then write this number into the text object. You can
   // move it around on the chart to get profit projections for
   // any price level you want. 
   if (ObjectFind("profit") != -1){
      pb = getPyramidBase();
      lp = ObjectGet("profit", OBJPROP_PRICE1);
      if (pb ==0){
         if (direction == SHORT){
            pb = getLine() - stop_distance * pip;
         }
         if (direction == LONG){
            pb = getLine() + stop_distance * pip;
         }
         if (direction == BIDIR){
            if (lp < getLine()){
               pb = getLine() - stop_distance * pip;
            }
            if (lp >= getLine()){
               pb = getLine() + stop_distance * pip;
            }
         }
      }
      tp = getTheoreticProfit(MathAbs(lp - pb));
      ObjectSetText("profit", "¯¯¯ " + DoubleToStr(MathRound(realized - getGlobal("realized") + tp), 0) + " " + AccountCurrency() + " profit projection ¯¯¯");
   }
   
}

/**
* Plot an arrow. Default is the price-exact dash symbol
* This function might be moved into common_functions soon
*/
string arrow(string name="", double price=0, datetime time=0, color clr=Red, int arrow_code=4){
   if (time == 0){
      time = TimeCurrent();
   }
   if (name == ""){
      name = "arrow_" + time;
   }
   if (price == 0){
      price = Bid;
   }
   if (ObjectFind(name) < 0){
      ObjectCreate(name, OBJ_ARROW, 0, time, price);
   }else{
      ObjectSet(name, OBJPROP_PRICE1, price);
      ObjectSet(name, OBJPROP_TIME1, time);
   }
   ObjectSet(name, OBJPROP_ARROWCODE, arrow_code);
   ObjectSet(name, OBJPROP_SCALE, 1);
   ObjectSet(name, OBJPROP_COLOR, clr);
   ObjectSet(name, OBJPROP_BACK, true);
   return(name);
}

/**
* plot the break even price into the chart
*/
void plotBreakEvenArrow(string arrow_name, double price){
   arrow(arrow_name + TimeCurrent(), price, 0, clr_breakeven_level);
}


/**
* plot the break-even Point (only a rough estimate plusminus less than one stop_distance,
* it will be most inaccurate just before hitting a stoploss (last trade negative).
* and this will be more obvious at the beginning of a new cycle when losses are still small
* and break even steps increments are still be big.
*
* Side effects: This function will also calculate auto-tp price and profit.
*
* FIXME: This whole break even calculation sucks comets through drinking straws!
* FIXME: Isn't there a more elegant way to calculate break even?
*/
void plotBreakEven(){
   double base = getPyramidBase();
   double be = 0;
   
   // loss is roughly the amount of realized stop hits. But I can't use this number
   // directly because after resuming a paused pyramid this number is wrong. So
   // I have to estimate it with the (always accurate) total profit and the current
   // distance from base. In mose cases the outcome of this calculation is equal
   // to the realized losses as displayed on the screen, only when resuming a pyramid 
   // it will differ and have the value it would have if the pyramid never had been paused.
   double distance = MathAbs(Close[0] - base);
   if ((level > 0 && Close[0] < base) || (level < 0 && Close[0] > base) || level == 0){
      distance = 0;
   }
   double loss = -(cycle_total_profit - getTheoreticProfit(distance));

   // this value should always be positive 
   // or 0 (or slightly below (rounding error)) in case we have a fresh pyramid.
   // If it is not positive (no loss yet) then we dont need to plot break even.
   if (loss <= 0 || !running){
      auto_tp_price = 0;
      auto_tp_profit = 0;
      return(0);
   }
   
   if (direction == LONG){
      if (base==0){
         base = getLine() + stop_distance * pip;
      }
      be = base + getBreakEven(loss);
      plotBreakEvenArrow("breakeven_long", be);
      auto_tp_price = be + pip * stop_distance * auto_tp;
      auto_tp_profit = getTheoreticProfit(MathAbs(auto_tp_price - base)) - loss;
   }
   
   if (direction == SHORT){
      if (base==0){
         base = getLine() - stop_distance * pip;
      }
      be = base - getBreakEven(loss);
      plotBreakEvenArrow("breakeven_short", be);
      auto_tp_price = be - pip * stop_distance * auto_tp;
      auto_tp_profit = getTheoreticProfit(MathAbs(auto_tp_price - base)) - loss;
   }
   
   if (direction == BIDIR){
      if (base == 0){
         base = getLine() + stop_distance * pip;
         plotBreakEvenArrow("breakeven_long", base + getBreakEven(loss));
         base = getLine() - stop_distance * pip;
         plotBreakEvenArrow("breakeven_short", base - getBreakEven(loss));
         auto_tp_price = 0;
         auto_tp_profit = 0;
      }else{
         if (getLotsOnTableSigned(magic) > 0){
            be = base + getBreakEven(loss);
            plotBreakEvenArrow("breakeven_long", be);
            auto_tp_price = be + pip * stop_distance * auto_tp;
            auto_tp_profit = getTheoreticProfit(MathAbs(auto_tp_price - base)) - loss;
         }else{
            be = base - getBreakEven(loss);
            plotBreakEvenArrow("breakeven_short", be);
            auto_tp_price = be - pip * stop_distance * auto_tp;
            auto_tp_profit = getTheoreticProfit(MathAbs(auto_tp_price - base)) - loss;
         }
      }
   }
   
   if (auto_tp < 1){
      auto_tp_price = 0;
      auto_tp_profit = 0;
   }
}


/**
* return the entry price of the first order of the pyramid.
* return 0 if we are flat.
*/
double getPyramidBase(){
   double d, max_d, sl;
   int i;
   int type=-1;
   
   // find the stoploss that is farest away from current price
   // we cannot just use the order open price because we might
   // be in resume mode and then all trades would be opened at
   // the same price. the only thing that works reliable is 
   // looking at the stoplossses
   for (i=0; i<OrdersTotal(); i++){
      OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
      if (OrderMagicNumber() == magic && OrderType() < 2){
         d = MathAbs(Close[0] - OrderStopLoss());
         if (d > max_d){
            max_d = d;
            sl = OrderStopLoss();
            type = OrderType();
         }
      }
   }
   
   if (type == OP_BUY){
      return(sl + pip * stop_distance);
   }
   
   if (type == OP_SELL){
      return(sl - pip * stop_distance);
   }
   
   return(0);
}

double getPyramidBase1(){
   int i;
   double pmax = -999999;
   double base = 0;
   for (i=0; i<OrdersTotal(); i++){
      OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
      if (OrderMagicNumber() == magic && OrderType() < 2){
         if (OrderProfit() > pmax){
            base = OrderOpenPrice();
            pmax = OrderProfit();
         }
      }
   }
   return(base);
}

/**
* return the floating profit that would result if
* price would be the specified distance away from
* the base of the pyramid
*/ 
double getTheoreticProfit(double distance){
   int n = MathFloor(distance / (stop_distance * pip));
   double remain = distance - n * stop_distance * pip;
   int mult = n * (n + 1) / 2;
   double profit = MarketInfo(Symbol(), MODE_TICKVALUE) * lots * stop_distance * points_per_pip * mult;
   profit = profit + MarketInfo(Symbol(), MODE_TICKVALUE) * lots * (remain/Point) * (n + 1);
   return(profit);
}

/**
* return the price move relative to base required to compensate realized losses
* FIXME: This algorithm does not qualify as "elegant", not even remotely. 
*/
double getBreakEven(double loss){
   double i = 0;
   
   while(true){
      if (getTheoreticProfit(pip * i) > loss){
         break;
      }
      i += stop_distance;
   }
   
   i -= stop_distance;
   while(true){
      if (getTheoreticProfit(pip * i) > loss){
         break;
      }
      i += 0.1;
   }

   return(pip * i);
}

int start(){
   static int numbars;
   onTick();
   if (Bars == numbars){
      return(0);
   }
   numbars = Bars;
   onOpen();
   return(0);
}

void setGlobal(string key, double value){
   GlobalVariableSet(name + magic + "_" + key, value);
}

double getGlobal(string key){
   return(GlobalVariableGet(name + magic + "_" + key));
}