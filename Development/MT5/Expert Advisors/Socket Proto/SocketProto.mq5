//+------------------------------------------------------------------+
//|                                                  SocketProto.mq5 |
//|                                      Copyright 2021, AlgoTradeup |
//|                                          https://algotradeup.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, AlgoTradeup"
#property link      "https://algotradeup.com"
#property version   "1.00"
#include <Controls\Dialog.mqh>
#include <Controls\Button.mqh>
#include <Controls\Label.mqh>
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int My_Socket_Handle = INVALID_HANDLE; 
string address = "127.0.0.1";
input string ClientName = "";
input int port = 9090;

CDialog Dialog;
CButton ConnectionBtn [2];
CButton SubscribeBtn[5];
CButton UnsubscribeBtn[5];
CButton TitleBtn;
CLabel  Labels[3];
CLabel  LabelsValues[3];
bool _isConnected = false;
enum Message_Type
  {
   HEARTBEAT = 0 ,
   LOGIN = 1,
   NEW_ORDER =2,
   UPDATE_ORDER =3,
   DELETE_ORDER = 4,
   REQUESET_ORDERS_SNAPSHOT = 5,
   AMMEND_POSITION =6,
   CLOSE_POSITION = 7,
   REQUEST_POSITION_SNAPSHOT =8,
   MD_SUBSCRIBE = 9,
   MD_UNSUBSCRIBE = 10,
   MARKET_DATA = 11,
   ORDER_SNAPSHOT = 12,
   POSITION_SNAPSHOT = 13
  };
int OnInit()
  {
//--- create timer
      
   Dialog.Create(ChartID(),"                                      ALGOTRADEUP",0,5,5,400,200);
   string dialogNumber=Dialog.Name();
   ObjectSetInteger(ChartID(),dialogNumber+"Caption",OBJPROP_BGCOLOR,clrGold);
   ObjectSetInteger(ChartID(),dialogNumber+"ClientBack",OBJPROP_BGCOLOR,clrWhite);
   //Connection Btn
   ConnectionBtn[0].Create(0,"Connect",0,5,6,0,0)                              ;
   ConnectionBtn[0].Text("Connect")                                            ;
   ConnectionBtn[0].FontSize(12)                                          ;                                    
   ConnectionBtn[0].Height(35)                                            ;
   ConnectionBtn[0].Width(150)                                            ;
   ConnectionBtn[0].Color(clrWhite)                                       ;
   ConnectionBtn[0].ColorBackground(clrLime)                             ;
   ConnectionBtn[0].ColorBorder(clrBlack)                                 ;
   Dialog.Add(ConnectionBtn[0]); 
   //Disconnect
   ConnectionBtn[1].Create(0,"Disconnect",0,160,6,0,0)                              ;
   ConnectionBtn[1].Text("Disconnect")                                            ;
   ConnectionBtn[1].FontSize(12)                                          ;                                    
   ConnectionBtn[1].Height(35)                                            ;
   ConnectionBtn[1].Width(150)                                            ;
   ConnectionBtn[1].Color(clrWhite)                                       ;
   ConnectionBtn[1].ColorBackground(clrRed)                             ;
   ConnectionBtn[1].ColorBorder(clrBlack)                                 ;                                          ;
   Dialog.Add(ConnectionBtn[1]); 
   //Symbol1
   Labels[0].Create(0,"Symbol_Lbl",0,10,45,0,0)                             ;
   Labels[0].Text("Symbol 1 : ")                                            ;
   Labels[0].FontSize(9)                                          ;                                    
   Labels[0].Height(35)                                            ;
   Labels[0].Width(150)                                            ;
   Labels[0].Color(clrBlack)                                       ;
   Dialog.Add(Labels[0]); 
   Labels[1].Create(0,"Symbol_Lbl2",0,10,75,0,0)                             ;
   Labels[1].Text("Symbol 2 : ")                                            ;
   Labels[1].FontSize(9)                                          ;                                    
   Labels[1].Height(35)                                            ;
   Labels[1].Width(150)                                            ;
   Labels[1].Color(clrBlack)                                       ;
   Dialog.Add(Labels[1]); 
   Labels[2].Create(0,"Symbol_Lbl3",0,10,105,0,0)                             ;
   Labels[2].Text("Symbol 3 : ")                                            ;
   Labels[2].FontSize(9)                                          ;                                    
   Labels[2].Height(35)                                            ;
   Labels[2].Width(150)                                            ;
   Labels[2].Color(clrBlack)                                       ;
   Dialog.Add(Labels[2]); 
   /*Labels[3].Create(0,"Symbol_Lbl4",0,10,135,0,0)                             ;
   Labels[3].Text("Symbol 4 : ")                                            ;
   Labels[3].FontSize(9)                                          ;                                    
   Labels[3].Height(35)                                            ;
   Labels[3].Width(150)                                            ;
   Labels[3].Color(clrBlack)                                       ;
   Dialog.Add(Labels[3]); 
 */  
   EventSetMillisecondTimer(500);
 //EventSetTimer(1);
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   Socket_Close(My_Socket_Handle);
   Dialog.Destroy(reason); 
//--- destroy timer
   EventKillTimer();
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick2(){
   My_Socket_Handle = Socket_Connect();
   string str_price_ask = Symbol()+" Ask: "+ DoubleToString(SymbolInfoDouble(_Symbol, SYMBOL_ASK)); 
   
   int res = Socket_Send(My_Socket_Handle,str_price_ask);
}

void OnTick()
  {
//---
   /*if(count == 10 && My_Socket_Handle==INVALID_HANDLE)return;
    if(My_Socket_Handle!=INVALID_HANDLE) 
    {
       if(count == 10){
         string quit_msg = "q<EOF>";
         Socket_Send(My_Socket_Handle, quit_msg);
         Socket_Close(My_Socket_Handle);
         return;
      }
   
      //Print("Connected to  localhost : ",port);
      int digit = SymbolInfoInteger(_Symbol,SYMBOL_DIGITS);
      string bid = DoubleToString(NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID),digit));
      string ask = DoubleToString(NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK),digit));
      string str_price_ask = TimeToString(TimeLocal(),TIME_MINUTES|TIME_SECONDS)+"-"+Symbol()+"{"+bid+","+ask+"}<EOF>"; 
      if(count == 10)str_price_ask = "q<EOF>";
      string received = Socket_Send(My_Socket_Handle, str_price_ask) ? socketreceive(My_Socket_Handle, 10) : ""; 
      Print("Server Response: "+received);
      count++;
      
    }
    else {
      Print("Socket creation error ",GetLastError()); 
      My_Socket_Handle = Socket_Connect();
    }*/  
   
  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
//---
   if(_isConnected){
      if(My_Socket_Handle!= INVALID_HANDLE){
         
            SendPriceQuote(Symbol());
            //SendPriceQuote("GC.Z21");
            string received = Socket_Receive(My_Socket_Handle, 10) ; 
            if(received != "")Print("Server Response: "+received);
         }  
    }
   
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
   if(id == CHARTEVENT_OBJECT_CLICK){
      if(sparam == "")
      return;
      if(sparam == "Connect"){
         //Connect
         My_Socket_Handle = Socket_Connect();
      }
      else if(sparam == "Disconnect"){
         if(My_Socket_Handle!=INVALID_HANDLE && _isConnected) 
         {
            string quit_msg = "q<EOF>";
            Socket_Send(My_Socket_Handle, quit_msg);
            Socket_Close(My_Socket_Handle);
         }
         else
            _isConnected = false;
         
         //Disconnect
      }
   }
}
void SendPriceQuote(string symbol){
   int digit = (int)SymbolInfoInteger(symbol,SYMBOL_DIGITS);
   string bid = DoubleToString(NormalizeDouble(SymbolInfoDouble(symbol, SYMBOL_BID),digit));
   string ask = DoubleToString(NormalizeDouble(SymbolInfoDouble(symbol, SYMBOL_ASK),digit));
   string str_price_ask = MessageHeader(MARKET_DATA)+TimeToString(TimeLocal(),TIME_DATE|TIME_MINUTES|TIME_SECONDS)+"|"+symbol+";"+bid+";"+ask+"|<EOF>"; 
   //if(count == 10)str_price_ask = "q<EOF>";
   Socket_Send(My_Socket_Handle, str_price_ask);


}
string MessageHeader(int type)
{
   return ""+type+"|"+ClientName+"|";
}
//+------------------------------------------------------------------+
int Socket_Connect()
{
  int h_socket = SocketCreate(SOCKET_DEFAULT);
  
  if(h_socket != INVALID_HANDLE)
  {
     if(SocketConnect(h_socket,address,port,500))
     {
      Print("Connected to Socket Server"); 
      Initialize(h_socket);
     
     }//if(SocketConnect
     else
     {
      Print("Fail connected to Socket Server. error code : ", GetLastError()); 
     }
  
  
  }//if(socket != INVALID_HANDLE)
  else
  {
   Print("Fail SocketCreate error code : ", GetLastError()); 
  }
  
  return h_socket; 
}
int retry = 0;
void Initialize(int socket_handle){
   if(ClientName !="" || retry < 30){
      string message = LOGIN+"|"+ ClientName+"|"+TimeToString(TimeLocal(),TIME_DATE|TIME_MINUTES|TIME_SECONDS)+"|Request|<EOF>";
      if(Socket_Send(socket_handle,message)){
         retry++;
         string rec = Socket_Receive(socket_handle,350);
         string sep = "|";
         ushort u_sep = StringGetCharacter(sep,0);
         string result[];
         int ack = StringSplit(rec,u_sep,result);
         if(ack > 0){
            string msg_type = result[0];
            string data = result[3];
            if(data == "Accept"){
               Sleep(500);
               _isConnected = true;
               retry = 0;
             }
            else{
               Socket_Close(socket_handle);               
                  //Initialize(socket_handle);
            }
         }
         
               
      }
         
   }
   else{
      _isConnected = false;
      Print("Socket Closing. Reason: Initialization failed");
      Socket_Close(socket_handle);
   }
   
   
}

void Socket_Close(int socket_handle)
{
   if(socket_handle != INVALID_HANDLE)
   {
      SocketClose(socket_handle);
      My_Socket_Handle = INVALID_HANDLE; 
      Print("Socket Closed");   
      _isConnected = false;   
   }

}

int Socket_Send(int socket_handle,string str_data)
{
   if(socket_handle == INVALID_HANDLE) return 0; 
   
   uchar bytes[]; 
   int byte_size = StringToCharArray(str_data,bytes)-1; 
   
   return SocketSend(socket_handle,bytes,byte_size);
      
}
string Socket_Receive(int sock,int timeout)
  {
   char rsp[];
   string result="";
   uint len;
   uint timeout_check=GetTickCount()+timeout;
   do
     {
      len=SocketIsReadable(sock);
      if(len)
        {
         int rsp_len;
         rsp_len=SocketRead(sock,rsp,len,timeout);
         if(rsp_len>0) 
           {
            result+=CharArrayToString(rsp,0,rsp_len); 
           }
        }
     }
   while((GetTickCount()<timeout_check) && !IsStopped());
   return result;
  }