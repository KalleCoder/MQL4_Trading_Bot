/**
 * @file Horizontal_Lines_Functions.mqh
 * @author KalleCoder
 * @brief 
 * Functions that draws and deletes horizontal lines 
 *
 * @version 1.0
 * @date 2024-01-03
 * 
 * @copyright Copyright (c) 2024
 * 
 */


// ------------------------------------------------------------------------------
// REMOVING LINES
// ------------------------------------------------------------------------------

/**
 * @brief 
 * Function to delete the last drawn horizontal line
 *
 * @param lastLineName[out]  The string name of the last horizontal line 
 */

void Delete_Last_Horizontal_Line(string &lastLineName) 
{
    if (StringLen(lastLineName) > 0) {
        ObjectDelete(0, lastLineName);
        lastLineName = ""; // Reset the lastLineName variable
    }
}

// ------------------------------------------------------------------------------
// Drawing WHITE LINES
// ------------------------------------------------------------------------------

/**
 * @brief 
 * Function to draw a white horizontal line at a specified price
 *
 * @param price The price where the line will be drawn 
 * @param lastLineName[out] The string where the new name will be placed  
 */

void Draw_White_Line(double price, string &lastLineName) {
    string lineName = "White_Line_" + DoubleToString(price, 6);
    
    
    // Check if the line already exists, and delete it if it does
    if (ObjectCreate(0, lineName, OBJ_HLINE, 0, 0, 0)) {
        ObjectDelete(0, lineName);
    }
    // Draw a new horizontal line
    ObjectCreate(0, lineName, OBJ_HLINE, 0, TimeCurrent(), price);
    
    // Set the line color to white
    ObjectSetInteger(0, lineName, OBJPROP_COLOR, clrWhite);
    lastLineName = lineName; // Store the name for future reference
}





