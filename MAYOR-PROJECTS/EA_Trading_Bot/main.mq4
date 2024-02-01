/**
 * @file main.mq4
 * @author KalleCoder
 * @brief 
 * This program is an Expert Advisor trading bot that works on the 15 minute timeframe and does automatic trading on the mt4 trading platform.
 * The program defines hard to breach price levels using a point system. 
 * After the price level has been breached the program should (if the price returns to the level) enter a trade on specific pattern terms. 
 * All functions that are not related to handeling the buy order and some specific arrays functions are in the include files. The rest are in the bottom of this file. 
 * @version 1.0
 * @date 2023-12-14
 * 
 * @copyright Copyright (c) 2023
 * 
 */

//+------------------------------------------------------------------+
//| INCLUDE FILES                                  |
//+------------------------------------------------------------------+
#include <Horizontal_Lines_Functions.mqh>
#include <Points_Functions.mqh>
#include <Price_Level_Functions.mqh>
#include <Entry_Bool_Functions.mqh>
//+------------------------------------------------------------------+
//| GLOBAL CANDLE TRACKERS                                 |
//+------------------------------------------------------------------+
// Candles since the last lowest or highest price has formed
int HIGH_PRICE_CANDLES = 0;
int CREATED_LINE_WHITE_CANDLES = 0;
int BROKEN_LINE_WHITE_CANDLES = 16;
int LAST_WHITE_POINT = 0;
int CANDLES_SINCE_SETTING_WHITE_INNER_LEVELS = 0;
//+------------------------------------------------------------------+
//| GLOBAL PRICE TRACKERS                                 |
//+------------------------------------------------------------------+
double HIGH_PRICE = 0.0;
double WHITE_PRICE = 0.0;
double WHITE_INNER_HIGH_PRICE = 0.0;  
double WHITE_INNER_HIGH_WICK_PRICE = 0.0;
double WHITE_INNER_LOW_PRICE = 0.0;
double WHITE_INNER_LOW_WICK_PRICE = 0.0;
double TAKE_PROFIT_PRICE_HIGH = 0.0;
input double PIP_RANGE_HISTORICAL = 0.0001;
input double PIP_RANGE_CURRENT = 0.0001;
input double TAKE_PROFIT_REDUCTION = 0.0005;
//+------------------------------------------------------------------+
//| GLOBAL POINT TRACKERS                                 |
//+------------------------------------------------------------------+
int WHITE_POINTS = 0;
//+------------------------------------------------------------------+
//| GLOBAL TIME TRACKERS                                 |
//+------------------------------------------------------------------+
datetime PREVIOUS_CANDLE_TIME = 0;
input int MORNING_HOUR = 7;
input int NIGHT_HOUR = 17;
input int HOURS_TO_LOOK_BACK = 24;
input int BROKEN_CANDLE_RESET_VALUE = 40;
input int PRICE_CANDLES_RESET_VALUE = 192;
//+------------------------------------------------------------------+
//| GLOBAL BOOL TRACKERS                                 |
//+------------------------------------------------------------------+
bool WHITE_LINE_DRAWN = false;
bool WHITE_HISTORY_SEARCH = true;
bool WHITE_ALLOW_POINT_SEARCH = true;
bool WHITE_LINE_BROKEN = false;
bool WHITE_INNER_LOW = false;
bool BROKE_BIG_PRICE_HIGH = false; 
bool BROKE_BIG_PRICE_LOW = false;
input bool SKIP_PRICE_LEVEL = false;
bool FOUND_HISTORY_WHITE_POINT = false;
//+------------------------------------------------------------------+
//| GLOBAL STRING VARIABLES                                 |
//+------------------------------------------------------------------+
string LAST_LINE_NAME_WHITE = "";
//+------------------------------------------------------------------+
//| GLOBAL ENTRY VARIABLES                                 |
//+------------------------------------------------------------------+
int AKTIVE_ORDERS = 0;
input int AKTIVE_ORDER_LIMIT = 2;
int ORDER_TICKETS_ARRAY[];
int LAST_TRADE_DAY = -1;
int DAILY_TRADE_COUNT = 0;
input int DAILY_TRADE_LIMIT = 1;
double WHITE_PROFIT_PRICE = 0.0;
input double LOT_SIZE = 1;
input double STOP_LOSS = 0.0025;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
//---
   PREVIOUS_CANDLE_TIME = iTime(NULL, PERIOD_M15, 1);
   AKTIVE_ORDERS = OrdersTotal();
   CalculateHighestPrices(HOURS_TO_LOOK_BACK, HIGH_PRICE, HIGH_PRICE_CANDLES); // The amount of hours to look back in history.
//---
   return(INIT_SUCCEEDED);
   
}

void OnTick()
{
   if (iTime(NULL, PERIOD_M15, 0) != PREVIOUS_CANDLE_TIME) // triggering after each new candle 
   {
      PREVIOUS_CANDLE_TIME = iTime(NULL, PERIOD_M15, 1); // making the above if statement work as intended   
      double current_close_price = iClose(NULL, PERIOD_M15, 1);
      double current_wick_high_price = iHigh(NULL, PERIOD_M15, 1);
      double current_wick_low_price = iLow(NULL, PERIOD_M15, 1);
      
      //+------------------------------------------------------------------+
      //| RESET ALL IF TO MUCH TIME SPENT                             |
      //+------------------------------------------------------------------+
      if (BROKEN_LINE_WHITE_CANDLES > BROKEN_CANDLE_RESET_VALUE || HIGH_PRICE_CANDLES > PRICE_CANDLES_RESET_VALUE) // deletes white line if it has existed for too long
      {  
         WHITE_POINTS = 0; // Reseting the points
         Delete_Last_Horizontal_Line(LAST_LINE_NAME_WHITE);
         CalculateHighestPrices(HOURS_TO_LOOK_BACK, HIGH_PRICE, HIGH_PRICE_CANDLES);
         Handle_Historical_Points_WHITE(HIGH_PRICE, PIP_RANGE_HISTORICAL, WHITE_POINTS, HOURS_TO_LOOK_BACK, HIGH_PRICE_CANDLES, FOUND_HISTORY_WHITE_POINT); /// ADDITION!!
         Handle_Future_Points_WHITE(HIGH_PRICE, PIP_RANGE_HISTORICAL, WHITE_POINTS, HIGH_PRICE_CANDLES); 
         
         if (WHITE_POINTS >= 1)
         {
            CREATED_LINE_WHITE_CANDLES = LAST_WHITE_POINT;
            WHITE_LINE_DRAWN = true;
            Delete_Last_Horizontal_Line(LAST_LINE_NAME_WHITE); // Delete old line
            Draw_White_Line(HIGH_PRICE, LAST_LINE_NAME_WHITE); // Drawing the horizontal line
            WHITE_HISTORY_SEARCH = true;  // now historical high levels can be searched for  
            WHITE_POINTS= 0;
            WHITE_ALLOW_POINT_SEARCH = false;
         }
         else
         {
            WHITE_LINE_DRAWN = false;
            CREATED_LINE_WHITE_CANDLES = 0;
            WHITE_POINTS = 0; 
            FOUND_HISTORY_WHITE_POINT = false;
            HIGH_PRICE_CANDLES = 0;
            WHITE_HISTORY_SEARCH = true;
            WHITE_ALLOW_POINT_SEARCH = true;   // Cant look for points during current closes before historical search 
         }

         WHITE_LINE_BROKEN = false;
         BROKEN_LINE_WHITE_CANDLES = 0;
         BROKE_BIG_PRICE_HIGH = false;
      }
 
      //+------------------------------------------------------------------+
      //| PRICE LEVELS                                   |
      //+------------------------------------------------------------------+
      if (current_close_price - HIGH_PRICE >= 0.0000) // the price needs to break the highest level with atleast 1 pip
      {
         HIGH_PRICE = current_close_price;   // Updating HIGH_PRICE 
         HIGH_PRICE_CANDLES = 0;             // resetting candles passed
         WHITE_POINTS = 0;                   // resetting the white points as a new high has been set
         WHITE_HISTORY_SEARCH = false;       // now historical high levels can be searched for   // MAYBE CHANGE SO IT ONLY CAN HAPPEN IF OLD ONE IS DEAD
         WHITE_ALLOW_POINT_SEARCH = false;   // Cant look for points during current closes before historical search
      }
      
     
         //+------------------------------------------------------------------+
      //| DELETING LINES                                   |
      //+------------------------------------------------------------------+
          
      //||||||||||||| DELETING LINES ||||||||||||||||||||
      if (HIGH_PRICE > WHITE_PRICE && CREATED_LINE_WHITE_CANDLES < 8) // removes white line if it Got breached right after being formed
      {
         if (WHITE_LINE_DRAWN == true && WHITE_POINTS < 2) // ADDITION!
         {
            Delete_Last_Horizontal_Line(LAST_LINE_NAME_WHITE);
            WHITE_LINE_DRAWN = false;
            WHITE_LINE_BROKEN = false;
            CREATED_LINE_WHITE_CANDLES = 0;
            BROKEN_LINE_WHITE_CANDLES = 0;
            LAST_WHITE_POINT = 0;
            BROKE_BIG_PRICE_HIGH = false;
            WHITE_POINTS = 0;                   // resetting the white points as a new high has been set
            WHITE_HISTORY_SEARCH = false;       // now historical high levels can be searched for   
            WHITE_ALLOW_POINT_SEARCH = false;   // Cant look for points during current closes before historical search
            FOUND_HISTORY_WHITE_POINT = false;
         }
      }
      
    
      
      //||||||||||||| TRACKING BREAKING OF LINE ||||||||||||||||||||
       
      if (WHITE_LINE_BROKEN == false && current_close_price - WHITE_PRICE >= 0.0001 && WHITE_PRICE != 0 && WHITE_LINE_DRAWN == TRUE)
      {
         
         Print("Broke the White line and white price is: ", WHITE_PRICE);
         BROKEN_LINE_WHITE_CANDLES = 0;
         WHITE_POINTS = 0;
         WHITE_LINE_BROKEN = true; // Now the candles can be tracked at the bottom
         Inner_High_Low_WHITE(WHITE_PRICE, BROKEN_LINE_WHITE_CANDLES,CREATED_LINE_WHITE_CANDLES, WHITE_INNER_LOW_PRICE, WHITE_INNER_HIGH_PRICE, WHITE_INNER_LOW_WICK_PRICE, WHITE_INNER_HIGH_WICK_PRICE); // getting the inner levels
         TAKE_PROFIT_PRICE_HIGH = NormalizeDouble(WHITE_PRICE, 2); // getting the take profit price by rounding up the line value
      }

     
      //+------------------------------------------------------------------+
      //| POINT SYSTEMS                                   |
      //+------------------------------------------------------------------+
      
      // ||||||||||| HISTORICAL POINTS FIRST|||||||||||||||||||||
      if (WHITE_HISTORY_SEARCH == false)
      {
         Handle_Historical_Points_WHITE(HIGH_PRICE, PIP_RANGE_HISTORICAL, WHITE_POINTS, 24, HIGH_PRICE_CANDLES, FOUND_HISTORY_WHITE_POINT);  // looking for points from previous candle closes and wicks
         WHITE_HISTORY_SEARCH = true;                                           // stops it from repeating and giving double points for the same levels 
         WHITE_ALLOW_POINT_SEARCH = true;
      }
  
      // ||||||||||| CURRENT POINT FINDER ||||||||||||||||||||||||||||
      if (WHITE_ALLOW_POINT_SEARCH == true)
      {
         Handle_Points_WHITE(HIGH_PRICE, PIP_RANGE_CURRENT, WHITE_POINTS, HIGH_PRICE_CANDLES); // Adds points if candle closes or wick reaches within 1 pip range from the HIGH_PRICE
      }
      

      
      //+------------------------------------------------------------------+
      //| DRAWING LINES                                   |
      //+------------------------------------------------------------------+
      //||||||||||||| CREATING LINES ||||||||||||||||||||
      
      if ((WHITE_POINTS >= 1 && WHITE_LINE_DRAWN == false && (HIGH_PRICE_CANDLES > 13 || FOUND_HISTORY_WHITE_POINT == true )) || (WHITE_POINTS >= 1 && BROKEN_LINE_WHITE_CANDLES >= 16 && (HIGH_PRICE_CANDLES > 13 || FOUND_HISTORY_WHITE_POINT == true))) // create a new line if 2 points has been reached
      {
         WHITE_PRICE = HIGH_PRICE;
         BROKEN_LINE_WHITE_CANDLES = 0;
         CREATED_LINE_WHITE_CANDLES = 0;
         WHITE_POINTS = 0;
         LAST_WHITE_POINT = 0;
         Delete_Last_Horizontal_Line(LAST_LINE_NAME_WHITE); // Delete old line
         Draw_White_Line(HIGH_PRICE, LAST_LINE_NAME_WHITE); // Drawing the horizontal line
         WHITE_LINE_DRAWN = true;                           // Stops it from repetedly drawing a new line
         WHITE_LINE_BROKEN = false;
         FOUND_HISTORY_WHITE_POINT = false;
      }

      //+------------------------------------------------------------------+
      //| ENTRY SYSTEMS                                   |
      //+------------------------------------------------------------------+
      
      //||||||||||||| INFO BEFORE GOING INTO TRADES ||||||||||||||||||||
      check_current_day_trades(); // Checks to see if the daily trade limit is reached or not
      check_status_in_array(ORDER_TICKETS_ARRAY); // Checks which of the entered trades are active or not
      AKTIVE_ORDERS = OrdersTotal();
      
      if (BROKE_BIG_PRICE_HIGH == false && current_close_price > WHITE_PRICE && WHITE_LINE_BROKEN == true && WHITE_PRICE != 0.0) 
      {
         take_profit_buy(TAKE_PROFIT_PRICE_HIGH, BROKEN_LINE_WHITE_CANDLES, BROKE_BIG_PRICE_HIGH); // Moves the profit price if the close price is over the takeprofit price
      }
      
      if (SKIP_PRICE_LEVEL == true) // testing without a hinder from big levels
      {
         take_profit_buy(TAKE_PROFIT_PRICE_HIGH, BROKEN_LINE_WHITE_CANDLES, BROKE_BIG_PRICE_HIGH); // Moves the profit price if the close price is over the takeprofit price
      }
      
      //||||||||||||| ENTERING TRADES ||||||||||||||||||||

      /// BUYS if the parameters are true
      if (WHITE_LINE_BROKEN == true && Hour() >= MORNING_HOUR && Hour() < NIGHT_HOUR && DAILY_TRADE_COUNT < DAILY_TRADE_LIMIT && AKTIVE_ORDERS < AKTIVE_ORDER_LIMIT && BROKEN_LINE_WHITE_CANDLES > 2)
      {
         if (TAKE_PROFIT_PRICE_HIGH - (current_close_price + STOP_LOSS * 3) > 0.0002 || SKIP_PRICE_LEVEL == true) // checks so the entry isnt to close to the tp
         {
            if (Close_On_Inner_High_WHITE(WHITE_INNER_HIGH_PRICE, BROKEN_LINE_WHITE_CANDLES) == true)
            {
               make_order_buy(TAKE_PROFIT_PRICE_HIGH);
            }
            
            if (Wick_On_Inner_High_WHITE(WHITE_INNER_HIGH_PRICE, BROKEN_LINE_WHITE_CANDLES) == true)
            {
               make_order_buy(TAKE_PROFIT_PRICE_HIGH);
            }
            
            if (Close_On_Inner_Low_WHITE(WHITE_INNER_LOW_PRICE, BROKEN_LINE_WHITE_CANDLES) == true)
            {
               make_order_buy(TAKE_PROFIT_PRICE_HIGH);
            }
            
            if (Wick_On_Inner_Low_WHITE(WHITE_INNER_LOW_PRICE, BROKEN_LINE_WHITE_CANDLES) == true)
            {
               make_order_buy(TAKE_PROFIT_PRICE_HIGH);
            }
            
            if (Wick_Below_Inner_High_WHITE(WHITE_INNER_HIGH_PRICE, BROKEN_LINE_WHITE_CANDLES) == true)
            {
               make_order_buy(TAKE_PROFIT_PRICE_HIGH);
            }
            
            if (Close_On_Inner_Low_Wick_WHITE(WHITE_INNER_LOW_WICK_PRICE, BROKEN_LINE_WHITE_CANDLES) == true)
            {
               make_order_buy(TAKE_PROFIT_PRICE_HIGH);
            }
            
            if (Wick_On_Inner_Low_Wick_WHITE(WHITE_INNER_LOW_WICK_PRICE, BROKEN_LINE_WHITE_CANDLES) == true)
            {
               make_order_buy(TAKE_PROFIT_PRICE_HIGH);
            }
            
            if (Close_On_Inner_High_Wick_WHITE(WHITE_INNER_HIGH_WICK_PRICE, BROKEN_LINE_WHITE_CANDLES) == true)
            {
               make_order_buy(TAKE_PROFIT_PRICE_HIGH);
            }
            
            if (Wick_On_Inner_High_Wick_WHITE(WHITE_INNER_HIGH_WICK_PRICE, BROKEN_LINE_WHITE_CANDLES) == true)
            {
               make_order_buy(TAKE_PROFIT_PRICE_HIGH);
            }
            
            if (Double_Bottom_Close_White(WHITE_PRICE, BROKEN_LINE_WHITE_CANDLES, WHITE_INNER_LOW_WICK_PRICE) == true)
            {
               make_order_buy(TAKE_PROFIT_PRICE_HIGH);
            }
            
            if (Double_Bottom_Wick_White(WHITE_PRICE, BROKEN_LINE_WHITE_CANDLES, WHITE_INNER_LOW_WICK_PRICE) == true)
            {
               make_order_buy(TAKE_PROFIT_PRICE_HIGH);
            }
            
            if (Double_Bottom_Close_On_Wick_White(WHITE_PRICE, BROKEN_LINE_WHITE_CANDLES, WHITE_INNER_LOW_WICK_PRICE) == true)
            {
               make_order_buy(TAKE_PROFIT_PRICE_HIGH);
            }
            
            if (Double_Bottom_Wick_On_Wick_White(WHITE_PRICE, BROKEN_LINE_WHITE_CANDLES, WHITE_INNER_LOW_WICK_PRICE) == true)
            {
               make_order_buy(TAKE_PROFIT_PRICE_HIGH);
            }              
         }
      }
      
      
      
      //+------------------------------------------------------------------+
      //| CANDLE INCREMENTS                                 |
      //+------------------------------------------------------------------+
      
      // |||||||||| INCREMENTING HIGH/LOW PRICES TIME |||||||||||||<
      HIGH_PRICE_CANDLES++;
      
      
      if (WHITE_ALLOW_POINT_SEARCH == true && WHITE_HISTORY_SEARCH == true && WHITE_POINTS > 0)
      {
         LAST_WHITE_POINT++;
      }

      // |||||||||| INCREMENTING TIME WHITE LINE HAS BEEN DRAWN |||||||||||||<
      if (WHITE_LINE_DRAWN == true)
      {
         CREATED_LINE_WHITE_CANDLES++;
      }
     
      // |||||||||| INCREMENTING TIME ABOVE WHITE LINE |||||||||||||<
      if (WHITE_LINE_BROKEN == true)
      {
         BROKEN_LINE_WHITE_CANDLES++;
      }
   }  
}



//+------------------------------------------------------------------+
//| ORDER TRACKING FUNCTIONS (CANT HAVE IN INCLUDE FILE)                      |
//+------------------------------------------------------------------+

/**
 * @brief 
 * Function to remove an element from an array by index
 *
 * @param array[] An array that contain the entered trades id's
 * @param index the location of what trade should be removed 
 */

void remove_element_from_array(int &array[], int index)
{
    if (index >= 0 && index < ArraySize(array))
    {
        for (int i = index; i < ArraySize(array) - 1; i++)
        {
            array[i] = array[i + 1];
        }
        ArrayResize(array, ArraySize(array) - 1);
    }
}


/**
 * @brief 
 * Function to check if all orders are active or not. Removes it from the array if not aktive. 
 *
 * @param array[] An array that contains the entered trades id's
 */

void check_status_in_array (int &array[])
{
   for (int j = 0; j < ArraySize(array);)
   {
      // Check the status of the order
      
      
      if (OrderSelect(array[j], SELECT_BY_TICKET))
      {
        int orderStatus = OrderType();
      
        if (orderStatus == OP_BUY || orderStatus == OP_SELL)
        {
            // The order is still open, move to the next order
            j++;
        }
        else
        {
            // Order has been closed or deleted, reduce the orderCount
            AKTIVE_ORDERS--;
      
            // Remove the closed order's ticket from the array
            remove_element_from_array(array, j);
        }
      }
      else
      {
        // Error selecting the order, move to the next order
        j++;
      }
   }
}


/**
 * @brief 
 * Function to check if it is the same day or not
 */
void check_current_day_trades()
{
   int current_day = DayOfWeek();
   
   // Check if it's a new day
   if (current_day != LAST_TRADE_DAY) 
   {
      // Reset the daily trade count
      DAILY_TRADE_COUNT = 0;
      // Update the last traded day
      LAST_TRADE_DAY = current_day;
   }
}


//+------------------------------------------------------------------+
//| ENTRY FUNCTIONS (CANT HAVE IN INCLUDE FILE)                      |
//+------------------------------------------------------------------+

/**
 * @brief 
 * Places a buy order in the market.
 * But first it checks if the daily tradecount is met. 
 * If a trade was executed it will be added to the trade array to keep track if its active or not. 
 * If the trade did not execute it will return the error message.  
 *
 * @param profitprice The price that a trade will take profit
 */


void make_order_buy(double profitprice)
{ 
   if (DAILY_TRADE_COUNT < DAILY_TRADE_LIMIT && AKTIVE_ORDERS < AKTIVE_ORDER_LIMIT)
   {
      int ticket = OrderSend(
       Symbol(),           // Symbol
       OP_BUY,             // Buy order type
       LOT_SIZE,           // Lot size
       Ask,                // Current Ask price (market price for buying)
       0,                 // Maximum slippage allowed
       Ask - STOP_LOSS,    // Stop loss (0 means no stop loss)
       profitprice - TAKE_PROFIT_REDUCTION,        // Take profit (0 means no take profit)
       "Buy Order",        // Comment for the order
       0,                  // Magic number (used to uniquely identify orders)
       0,                  // Expiration time (0 means the order is valid until manually closed)
       Blue                // Color for the order on the chart
         );
      
      // Check if the order was successfully opened
      if (ticket > 0) 
      {
         Print("BUY order opened successfully. Ticket: ", ticket);
         // Resize the array and store the ticket number
         ArrayResize(ORDER_TICKETS_ARRAY, ArraySize(ORDER_TICKETS_ARRAY) + 1);
         ORDER_TICKETS_ARRAY[ArraySize(ORDER_TICKETS_ARRAY) - 1] = ticket;
         DAILY_TRADE_COUNT++;
      
      } 
      else 
      {
          Print("Error opening BUY order. Error code: ", GetLastError());
      }
   }
}  
