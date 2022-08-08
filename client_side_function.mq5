//+------------------------------------------------------------------+
//|                                                   HeikenKill.mq5 |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, https://leereal.me"
#property link      "https://leereal.me"
#property version   "1.00"


#include<Trade/Trade.mqh>
//+------------------------------------------------------------------+
//| Variables and Inputs                                             |
//+------------------------------------------------------------------+

CTrade trade;

//+------------------------------------------------------------------+
//|   ENUM TYPE CANDLESTICK                                          |
//+------------------------------------------------------------------+
enum TYPE_CANDLESTICK
  {
   CAND_NONE,           //Unknown
   CAND_MARIBOZU,       //Maribozu
   CAND_MARIBOZU_LONG,  //Maribozu long
   CAND_DOJI,           //Doji
   CAND_SPIN_TOP,       //Spins
   CAND_HAMMER,         //Hammer
   CAND_INVERT_HAMMER,  //Inverted Hammer
   CAND_LONG,           //Long
   CAND_SHORT,          //Short
   CAND_STAR            //Star
  };
//+------------------------------------------------------------------+
//|   TYPE_TREND                                                     |
//+------------------------------------------------------------------+
enum TYPE_TREND
  {
   UPPER,   //Ascending
   DOWN,    //Descending
   LATERAL  //Lateral
  };
//+------------------------------------------------------------------+
//|   CANDLE_STRUCTURE                                               |
//+------------------------------------------------------------------+
struct CANDLE_STRUCTURE
  {
   double            open,high,low,close; // OHLC
   datetime          time;     //Time
   TYPE_TREND        trend;    //Trend
   bool              bull;     //Bullish candlestick
   double            bodysize; //Size of body
   TYPE_CANDLESTICK  type;     //Type of candlestick
  };

input double      Lotsize        =  0.5;     //Lot Size
input ulong       magicNumber    =  5271;    //Magic Number
input string      PriceAction    =  "<=== Price Action ===>";//<==========================>
input bool        hammer         =  true;    //Hammer(Bottom)
input bool        shootingStar   =  true;    //Shooting Star(Top)
input bool        buEngulfing    =  true;    //Bullish Engulfing
input bool        beEngulfing    =  true;    //Bearing Engulfing
input bool        buTweezers     =  true;    //Bullish Tweezers
input bool        beTweezers     =  true;    //Bearing Tweezers


int handleHeikenAshi;
int handleBB;
int barsTotal;
ulong positionTicket;
string bollingerTradeValue;
double bbUpper[], bbLower[], bbMiddle[];
double haOpen[], haClose[],haHigh[],haLow[]; 
  TYPE_CANDLESTICK candle_type;  
  CANDLE_STRUCTURE cand_str;

//Python connect variable
int      socket;   // Socket handle
input string Address="localhost";
input int    Port   =8888;
bool         ExtTLS =false;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   barsTotal = iBars(_Symbol,PERIOD_CURRENT);
   handleHeikenAshi = iCustom(_Symbol,PERIOD_CURRENT,"Examples\\Heiken_Ashi.ex5");
   handleBB = iBands(_Symbol,PERIOD_CURRENT,20,0,1.5,PRICE_CLOSE);

 ArraySetAsSeries(haOpen,true) ;
 ArraySetAsSeries(haClose,true) ;
 ArraySetAsSeries(haHigh,true) ;
 ArraySetAsSeries(haLow,true) ;
 
ArraySetAsSeries(bbUpper,true) ;
ArraySetAsSeries(bbLower,true) ;
ArraySetAsSeries(bbMiddle,true) ;
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {  
   int bars = iBars(_Symbol,PERIOD_CURRENT);  
   CopyBuffer(handleBB,BASE_LINE,1,1,bbMiddle);
   CopyBuffer(handleBB,UPPER_BAND,1,1,bbUpper);
   CopyBuffer(handleBB,LOWER_BAND,1,1,bbLower);
   bollingerConfirm(); //Check bollinger band     
   //Print("BB is ready to:" + bollingerTradeValue); 
  
   
 
   
   //Check if it is a new bar first and proceed if not new bar move
   if(barsTotal != bars){ 
    sendSignal("buy");
      trade.SetExpertMagicNumber(magicNumber) ;

      barsTotal = bars; //Reset total bars with the new number
      CopyBuffer(handleHeikenAshi,0,1,7,haOpen); // 0 is the open of candle, 1 means the first candle, 1 means only one candle)
      CopyBuffer(handleHeikenAshi,3,1,7,haClose);// 3 is the close of candle, 1 means the first candle, 1 means only one candle)
      CopyBuffer(handleHeikenAshi,1,1,7,haHigh);// 3 is the close of candle, 1 means the first candle, 1 means only one candle)
      CopyBuffer(handleHeikenAshi,2,1,7,haLow);// 3 is the close of candle, 1 means the first candle, 1 means only one candle)
      closePosition(); 
         
      //Print it to the chart
      Comment("\n HA Open: ",DoubleToString(haOpen[0],_Digits),
               "\n HA High: ",DoubleToString(haHigh[0],_Digits),
               "\n HA Lower: ",DoubleToString(haLow[0],_Digits),
               "\n HA Close: ",DoubleToString(haClose[0],_Digits));
           
          //Close position if heiken ashi change color
          /* for(int i=PositionsTotal()-1;i>=0;i--)
           {   
           
            ulong tkt=PositionGetTicket(i);
            if(tkt>0)
              {       
               if(PositionGetInteger(POSITION_MAGIC)==magicNumber && PositionGetString(POSITION_SYMBOL)==Symbol() && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY && haOpen[0] > haClose[0])
                 {
                     if(trade.PositionClose(tkt)){
                        positionTicket = 0;         
                     }
                 }             
               if(PositionGetInteger(POSITION_MAGIC)==magicNumber && PositionGetString(POSITION_SYMBOL)==Symbol() && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL && haOpen[0] < haClose[0])
                 {                  
                     if(trade.PositionClose(tkt)){
                        positionTicket = 0;         
                     }
                 }
              }
           }*/
            
      //Checking if Heiken Ashi is a Blue or Red candle
      if( checkPriceAction() == true && bollingerTradeValue == "buy" ){
         Alert("Buy or Call Previous heiken ashi is Blue");
         //Buy on deriv api
         sendSignal("buy"); 
         
         //Check if there is a sell running and close it first
         /*if(positionTicket > 0){
            if(PositionSelectByTicket(positionTicket)){
               if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL )
                  //closePosition(); 
             }
         }  */    
         
         //MT5 Buy  
         if(positionTicket <= 0){    
            if(openBuy()) //Open buy position
               Print(_Symbol+" buy opened successfully");
         }         
      }
      else if( checkPriceAction() == true && bollingerTradeValue == "sell"){
         Alert("Sell / Put Previous heiken ashi is Red");
         
         //Sell / Put on deriv api
         sendSignal("sell"); 
                  
         //Check if there is a buy running and close it first
         /*if(positionTicket > 0){
            if(PositionSelectByTicket(positionTicket)){
               if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
                  closePosition(); 
             }
         }*/
         
         //MT5 Sell
         if(positionTicket <= 0){         
            if(openSell())
               Print(_Symbol+" sell opened successfully");            
         }
      }
    }
      //Checking if previous HA candle is bigger than            
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Custom Functions by Leereal                                      |
//+------------------------------------------------------------------+

bool openBuy(){
   //Set all buy parameters here
   if(trade.Buy(Lotsize)){
      trade.SetExpertMagicNumber(magicNumber);
      positionTicket = trade.ResultOrder();
      bollingerTradeValue = "";   
      return true;
     }
     else{
      return false;
     }
}

bool openSell(){
   //Set all sell parameters here
   if(trade.Sell(Lotsize)){
      trade.SetExpertMagicNumber(magicNumber);
      positionTicket = trade.ResultOrder();
      bollingerTradeValue = "";   
      return true;
      }
    else{
      return false;
    }
}
bool checkPriceAction(){
   /*bool checkHammer        = false;
   bool checkShootingStar  = false;
   bool checkBuEngulfing   = false;
   bool checkBeEngulfing   = false;
   bool checkBuTweezers    = false;
   bool checkBeTweezers    = false;   

   if(haOpen || checkShootingStar || checkBuEngulfing || checkBeEngulfing || checkBuTweezers || checkBeTweezers){
      Comment("\n Price Action confirmed");
      return true;
   }*/
   RecognizeCandle();
   if(haOpen[0] < haClose[0] && cand_str.type == CAND_HAMMER){
      if(haOpen[1]<haOpen[2])
      if(haOpen[2]<haOpen[3])
      if(haOpen[3]<haOpen[4])
      if(haOpen[4]<haOpen[5])
      if(haOpen[5]<haOpen[6]){ 
      Print("Third Hammer Candle and Trend confirmed");    
      return true;
      }     
   }
   if(haOpen[0] > haClose[0] && cand_str.type == CAND_SPIN_TOP){
      if(haOpen[1]>haOpen[2])
      if(haOpen[2]>haOpen[3])
      if(haOpen[3]>haOpen[4])
      if(haOpen[4]>haOpen[5])
      if(haOpen[5]>haOpen[6]){ 
      Print("Third Spinning Top Candle and Trend confirmed");   
      return true;   
      }         
   }
    
   return false;
 
}

void bollingerConfirm(){  
   //If it touches upper band set value to "sell"   
      if(NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),_Digits) >= bbUpper[0] ){
         Print("Bollinger waiting for Sell Confirmation");
          bollingerTradeValue = "sell";     
       }
      
   //If it touches lower band set value to "buy"
      if(NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),_Digits) <= bbLower[0] ){
         Print("Bollinger waiting for Buy Confirmation");
         bollingerTradeValue = "buy";
      }
      
   //If it touches middle band set value to ""
      if(NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),_Digits) == bbMiddle[0] ){
         bollingerTradeValue = "";        
      }
}

//+------------------------------------------------------------------+
//|                                                                  |
double TotalProfit()
  {
   double pft=0;
   for(int i=PositionsTotal()-1;i>=0;i--)
     {   
      ulong ticket=PositionGetTicket(i);
      if(ticket>0)    
        {
         if(PositionGetInteger(POSITION_MAGIC)==magicNumber && PositionGetString(POSITION_SYMBOL)==Symbol())
           {
            pft+=PositionGetDouble(POSITION_PROFIT);
           }
        }
     }
   return(pft);
  }
//+------------------------------------------------------------------+

/*void sendSignal(string trade_option){
  //Sending Signal
   Print("[INFO]\tSending Signal");
   string msg;
   StringConcatenate(msg, "{\"symbol\":\"",_Symbol,"\",","\"trade_option\":\"",trade_option,"\"}");
   char req[];
   int len = StringToCharArray(msg, req)-1;
   SocketSend(socket, req, len);
   Comment("Socket Send");
}
*/

//+------------------------------------------------------------------+
//|   Function of determining of candlestick                         |
//+------------------------------------------------------------------+
void RecognizeCandle()
  {  
  cand_str.high = haHigh[1];
  cand_str.close = haClose[1];
  cand_str.open = haOpen[1];
  cand_str.low = haLow[1];

//--- Determine if it's a bullish or a bearish candlestick
   cand_str.bull=cand_str.open<cand_str.close;
//--- Get the absolute size of body of candlestick
   cand_str.bodysize=MathAbs(cand_str.open-cand_str.close);
//--- Get sizes of shadows
   double shade_low=cand_str.close-cand_str.low;
   double shade_high=cand_str.high-cand_str.open;
   if(cand_str.bull)
     {
      shade_low=cand_str.open-cand_str.low;
      shade_high=cand_str.high-cand_str.close;
     }
   double HL=cand_str.high-cand_str.low;

//--- Determine type of candlestick   
   cand_str.type=CAND_NONE;

//--- hammer
   if(shade_low>=cand_str.bodysize && shade_high<cand_str.bodysize) cand_str.type=CAND_HAMMER;
//--- spinning top
   if(shade_high>=cand_str.bodysize && shade_low<cand_str.bodysize) cand_str.type=CAND_SPIN_TOP;
  }
//+------------------------------------------------------------------+



void closePosition(){
   for(int i=PositionsTotal()-1;i>=0;i--)
     {   
      ulong tkt=PositionGetTicket(i);
      if(tkt>0)
        {       
         if(PositionGetInteger(POSITION_MAGIC)==magicNumber && PositionGetString(POSITION_SYMBOL)==Symbol() && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)// && haOpen[0] > haClose[0] //This close on candle color change
           {
               if(trade.PositionClose(tkt)){
                  positionTicket = 0;         
               }
           }
         if(PositionGetInteger(POSITION_MAGIC)==magicNumber && PositionGetString(POSITION_SYMBOL)==Symbol() && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)//  && haOpen[0] < haClose[0] //This close on candle color change
           {
               if(trade.PositionClose(tkt)){
                  positionTicket = 0;         
               }
           }
        }
     }
   
}

//+------------------------------------------------------------------+
//| Send command to the server                                       |
//+------------------------------------------------------------------+
bool HTTPSend(int socket,string request)
  {
   char req[];
   int  len=StringToCharArray(request,req)-1;
   if(len<0)
      return(false);
//--- if secure TLS connection is used via the port 443
   if(ExtTLS)
      return(SocketTlsSend(socket,req,len)==len);
//--- if standard TCP connection is used
   return(SocketSend(socket,req,len)==len);
  }
//+------------------------------------------------------------------+
//| Read server response                                             |
//+------------------------------------------------------------------+
bool HTTPRecv(int socket,uint timeout)
  {
   char   rsp[];
   string result;
   uint   timeout_check=GetTickCount()+timeout;
//--- read data from sockets till they are still present but not longer than timeout
   do
     {
      uint len=SocketIsReadable(socket);
      if(len)
        {
         int rsp_len;
         //--- various reading commands depending on whether the connection is secure or not
         if(ExtTLS)
            rsp_len=SocketTlsRead(socket,rsp,len);
         else
            rsp_len=SocketRead(socket,rsp,len,timeout);
         //--- analyze the response
         if(rsp_len>0)
           {
            result+=CharArrayToString(rsp,0,rsp_len);
            //--- print only the response header
            int header_end=StringFind(result,"\r\n\r\n");
            if(header_end>0)
              {
               Print("HTTP answer header received:");
               Print(StringSubstr(result,0,header_end));
               return(true);
              }
           }
        }
     }
   while(GetTickCount()<timeout_check && !IsStopped());
   return(false);
  }
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void sendSignal(string trade_option){

   socket=SocketCreate();
//--- check the handle
   if(socket!=INVALID_HANDLE)
     {
      //--- connect if all is well
      if(SocketConnect(socket,Address,Port,1000))
        {
         Print("Established connection to ",Address,":",Port);
 
         string   subject,issuer,serial,thumbprint;
         datetime expiration;
         //--- if connection is secured by the certificate, display its data
         if(SocketTlsCertificate(socket,subject,issuer,serial,thumbprint,expiration))
           {
            Print("TLS certificate:");
            Print("   Owner:  ",subject);
            Print("   Issuer:  ",issuer);
            Print("   Number:     ",serial);
            Print("   Print: ",thumbprint);
            Print("   Expiration: ",expiration);
            ExtTLS=true;
           }
         //--- send GET request to the server
          string msg;
          StringConcatenate(msg, "{\"symbol\":\"",_Symbol,"\",","\"trade_option\":\"",trade_option,"\",\"msg_type\":\"signal\"}");
         //string signal =  "{\"symbol\":\"",_Symbol,"\",","\"trade_option\":\"",trade_option,"\",\"msg_type\":\"signal\"}");
         if(HTTPSend(socket,msg))
           {
            Print("GET request sent");
            //--- read the response
            if(!HTTPRecv(socket,1000))
               Print("Failed to get a response, error ",GetLastError());
           }
         else
            Print("Failed to send GET request, error ",GetLastError());
        }
      else
        {
         Print("Connection to ",Address,":",Port," failed, error ",GetLastError());
        }
      //--- close a socket after using
      SocketClose(socket);
     }
   else
      Print("Failed to create a socket, error ",GetLastError());
  }
//+------------------------------------------------------------------+