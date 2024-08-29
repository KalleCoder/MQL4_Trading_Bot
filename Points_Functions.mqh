/**
 * @file Points_Functions.mqh
 * @author KalleCoder
 * @brief 
 * The functions in this file controlles the point assertion in the main program. 
 * It looks into the history, the present and the future, depending on the situation. 
 *
 * @version 1.0
 * @date 2023-12-14
 * 
 * @copyright Copyright (c) 2023
 * 
 */


// ------------------------------------------------------------------------------
// WHITE LINE POINTS (BULLISH)
// ------------------------------------------------------------------------------

/**
 * @brief 
 * This function increments the High_Points if a candle closes within the Pip_Range 
 * Also increments the points if a candle high does the same.  
 *
 * @param Highest_Price The Highest price the bot has recorded
 * @param Pip_Range The range of which how close a candle or wick can close to a level
 * @param High_Points[out] The points to now when to draw a level
 * @param high_candles_passed Amount of candles passed since the high level was found
 */
// Function to handle point assertion and comparison
void Handle_Points_WHITE(double Highest_Price, double Pip_Range, int &High_Points, int high_candles_passed)
{
    double Closing_Price = iClose(NULL, PERIOD_M15, 2);
    double Wick_High = iHigh(NULL, PERIOD_M15, 2);
    
    double pipDifference = Highest_Price - Closing_Price;
    double pipDifference_wick = Highest_Price - Wick_High;

      
    if (high_candles_passed >= 12)
    {
       if (pipDifference >= 0 && pipDifference <= Pip_Range)
       {
           // Condition 1: Closing price is within the pipRange under the highest price
           if (Closing_Price > iClose(NULL, PERIOD_M15, 3) && Closing_Price > iClose(NULL, PERIOD_M15, 1))
           {
              High_Points++;
           }
       }
       else if (pipDifference_wick >= 0 && pipDifference_wick <= Pip_Range + 0.0001)
       {
           //Condition 2: Wick high is within the pipRange
           if (Wick_High > iClose(NULL, PERIOD_M15, 3) && Wick_High > iClose(NULL, PERIOD_M15, 1))
           {
              High_Points++;
           }
           
       }
    }
}

/**
 * @brief 
 * Does a very similar thing to the function above, however it goes back in history. 
 * Older candle highs and closes has a larger pipRange because they have more strength. 
 *
* @param Highest_Price The Highest price the bot has recorded
 * @param Pip_Range The range of which how close a candle or wick can close to a level
 * @param High_Points[out] The points to now when to draw a level
 * @param hoursToLookBack The hours the user want to look back in history
 * @param high_candles_passed Amount of candles passed since the high level was found
 * @param found_history_points[out] If you found points or not
 */

// Function to handle points assertion and comparison with historical data
void Handle_Historical_Points_WHITE(double Highest_Price, double pipRange, int &High_Points, int hoursToLookBack, int high_candles_passed, bool &found_history_points)
{
    int candlesToLookBack = hoursToLookBack * 4; // Assuming 15-minute candles

    for (int i = 8 + high_candles_passed; i < candlesToLookBack + high_candles_passed; i++)  // skipping to look at the latest 2 hours
    {
        double historicalClosingPrice = iClose(NULL, PERIOD_M15, i);
        double historicalWickHigh = iHigh(NULL, PERIOD_M15, i);
        datetime historicalTime = iTime(NULL, PERIOD_M15, i);

        double pipDifference = Highest_Price - historicalClosingPrice;
        double pipDifference_Wick = Highest_Price - historicalWickHigh;
        
        if (historicalClosingPrice > Highest_Price)
        {
           break; // exit if the price goes above in history Cant look for levels thats above it. 
        }
        else
        {   
           if(i < 50) // CANDLES CLOSER TO THE NEW HIGH HAS A HIGHER STANDARD OF ACCURACY!
           {
              if (pipDifference >= 0 && pipDifference <= pipRange && iClose(NULL, PERIOD_M15, i+1) < Highest_Price)// last part to se that the candles after dont fuck it up
              {
                  // Condition 1: Closing price is within the pipRange under the highest price
                  if (historicalClosingPrice > iClose(NULL, PERIOD_M15, i + 1) && historicalClosingPrice > iClose(NULL, PERIOD_M15, i - 1))
                  {
                     High_Points++;
                     found_history_points = true;
                  }
                 
              }
              else if (pipDifference_Wick >= 0 && pipDifference_Wick <= pipRange && iClose(NULL, PERIOD_M15, i+1) < Highest_Price) 
              {
                  // Condition 2: Wick high is within the pipRange
                  if(historicalWickHigh > iLow(NULL, PERIOD_M15, i+1))
                  { 
                     High_Points++;
                     found_history_points = true;
                  }    
              }
           }
           else // WHEN OLDER IT CAN TAKE A LARGE PIP RANGE
           {
               if (pipDifference >= 0 && pipDifference <= pipRange + 0.0002 && iClose(NULL, PERIOD_M15, i+1) < Highest_Price)// last part to se that the candles after dont fuck it up
              {
                  // Condition 1: Closing price is within the pipRange under the highest price
                  if (historicalClosingPrice > iClose(NULL, PERIOD_M15, i + 1) && historicalClosingPrice > iClose(NULL, PERIOD_M15, i - 1))
                  {
                     High_Points++;
                     found_history_points = true;
                  }
                 
              }
              else if (pipDifference_Wick >= 0 && pipDifference_Wick <= pipRange + 0.0002 && iClose(NULL, PERIOD_M15, i+1) < Highest_Price) 
              {
                  // Condition 2: Wick high is within the pipRange
                  if(historicalWickHigh > iLow(NULL, PERIOD_M15, i+1))
                  { 
                     High_Points++;
                     found_history_points = true;
                  }    
              }
           }
        } 
    }
}

/**
 * @brief 
 * This functions works as the function above, however it starts from an older point in time.
 * This function gets triggered when a large amount of time has went and everything has been reset.
 * During that occation a new historical high is found and you need to look into the "future" from that creation until the current candle to see if that level
 * is a white line or not. 
 *
 * @param Highest_Price The Highest price the bot has recorded
 * @param Pip_Range The range of which how close a candle or wick can close to a level
 * @param High_Points[out] The points to now when to draw a level
 * @param high_candles_passed Amount of candles passed since the high level was found
 */

// Function to handle points assertion and comparison with future data
void Handle_Future_Points_WHITE(double Highest_Price, double pipRange, int &High_Points, int high_candles_passed)
{
   for (int i = 8; i < high_candles_passed - 8; i++)  // skipping to look at the latest 2 hours
   {
      double historicalClosingPrice = iClose(NULL, PERIOD_M15, i);
      double historicalWickHigh = iHigh(NULL, PERIOD_M15, i);
      datetime historicalTime = iTime(NULL, PERIOD_M15, i);
      
      double pipDifference = Highest_Price - historicalClosingPrice;
      double pipDifference_Wick = Highest_Price - historicalWickHigh;
      
      if (historicalClosingPrice > Highest_Price)
      {
        break; // exit if the price goes above in history Cant look for levels thats above it. 
      }
      else
      {
         if( i > high_candles_passed - high_candles_passed/2 ) // CANDLES close to the high has a higher standard
         {
            if (pipDifference >= 0 && pipDifference <= pipRange && iClose(NULL, PERIOD_M15, i+1) < Highest_Price)// last part to se that the candles after dont fuck it up
            {
               // Condition 1: Closing price is within the pipRange under the highest price
               if (historicalClosingPrice > iClose(NULL, PERIOD_M15, i + 1) && historicalClosingPrice > iClose(NULL, PERIOD_M15, i - 1))
               {
                  High_Points++;
               }
              
            }
            else if (pipDifference_Wick >= 0 && pipDifference_Wick <= pipRange && iClose(NULL, PERIOD_M15, i+1) < Highest_Price) 
            {
               // Condition 2: Wick high is within the pipRange
               if(historicalWickHigh > iLow(NULL, PERIOD_M15, i+1))
               { 
                  High_Points++;
               }    
            }
         }
         else
         {
           if (pipDifference >= 0 && pipDifference <= pipRange + 0.0002 && iClose(NULL, PERIOD_M15, i+1) < Highest_Price)// last part to se that the candles after dont fuck it up
            {
               // Condition 1: Closing price is within the pipRange under the highest price
               if (historicalClosingPrice > iClose(NULL, PERIOD_M15, i + 1) && historicalClosingPrice > iClose(NULL, PERIOD_M15, i - 1))
               {
                  High_Points++;
               }
              
            }
            else if (pipDifference_Wick >= 0 && pipDifference_Wick <= pipRange + 0.0002 && iClose(NULL, PERIOD_M15, i+1) < Highest_Price) 
            {
               // Condition 2: Wick high is within the pipRange
               if(historicalWickHigh > iLow(NULL, PERIOD_M15, i+1))
               { 
                  High_Points++;
               }    
            } 
         }
      } 
   }
}
