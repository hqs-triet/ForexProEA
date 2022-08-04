//+--------------------------------------------------------------------------+
//|                                           ForexProEA_6_6_MultipleSMA.mq5 |
//|                                                             Forex Pro EA |
//|                              https://www.facebook.com/groups/forexproea/ |
//+--------------------------------------------------------------------------+
#property copyright "Forex Pro EA"
#property link      "https://www.facebook.com/groups/forexproea/"
#property version   "1.00"
#property description "Resistance and support zone"

#include "..\\libs\\Common.mqh"
#include "..\\libs\\Graph.mqh"
#include <Generic\ArrayList.mqh>
// Khai báo sử dụng chỉ báo chung với biểu đồ chính
#property indicator_chart_window
#property indicator_buffers 4
#property indicator_plots 2

// -----------------------------------------------
// Chỉ báo tín hiệu 
#property indicator_label1  "Resistance"
#property indicator_type1   DRAW_ARROW
#property indicator_color1  clrBlue
#property indicator_width1  5

#property indicator_label2  "Support"
#property indicator_type2   DRAW_ARROW
#property indicator_color2  clrRed
#property indicator_width2  5

#resource "\\Indicators\\Examples\\ZigZagColor.ex5"
//--------------------------------------------------------------
// Tham số đầu vào (input)
//--------------------------------------------------------------
input int InpZone = 150;
input int InpLookbackPoint = 10;
//--------------------------------------------------------------
//const int MAX_POINT = 10;

double m_resBuffer[], m_supBuffer[],
       m_zigzagTopBuffer[], m_zigzagBottomBuffer[];
int m_zigzagHandler;

CChartObjectTrend *m_lineTop[], *m_lineBottom[];
CChartObjectRectangle *m_recTop[], *m_recBottom[];
//+------------------------------------------------------------------+
//| Sự kiện khởi tạo
//+------------------------------------------------------------------+
int OnInit()
{
    InitSeries(m_zigzagTopBuffer);
    InitSeries(m_zigzagBottomBuffer);
    InitSeries(m_resBuffer);
    InitSeries(m_supBuffer);
    
    // Thiết lập hiển thị chính xác số thập phân
    IndicatorSetInteger(INDICATOR_DIGITS, _Digits + 1);
    
    // Thiết lập bộ đệm cho chỉ báo tín hiệu
    SetIndexBuffer(2, m_resBuffer, INDICATOR_CALCULATIONS);
    SetIndexBuffer(3, m_supBuffer, INDICATOR_CALCULATIONS);
    SetIndexBuffer(0, m_zigzagTopBuffer, INDICATOR_DATA);
    SetIndexBuffer(1, m_zigzagBottomBuffer, INDICATOR_DATA);
    
    // Với những vị trí không có giá trị, thiết lập giá trị 0.0
    PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, 0.0);
    PlotIndexSetDouble(1, PLOT_EMPTY_VALUE, 0.0);
    
    // Thiết lập kiểu vẽ của đường chỉ báo tín hiệu BUY/SELL
    // Giá trị code 159 theo font Wingdings là kiểu vẽ vòng tròn
    PlotIndexSetInteger(0, PLOT_ARROW, 159);
    PlotIndexSetInteger(1, PLOT_ARROW, 159);
    
    
    m_zigzagHandler = iCustom(NULL, 0, "::Indicators\\Examples\\ZigZagColor",
                              12,5,3);
    
    if(m_zigzagHandler <= 0)
    {
        Print("Cannot initalize zigzag");
        return INIT_FAILED;
    }
    
    ArrayResize(m_lineBottom, InpLookbackPoint);
    ArrayResize(m_lineTop, InpLookbackPoint);
    ArrayResize(m_recBottom, InpLookbackPoint);
    ArrayResize(m_recTop, InpLookbackPoint);
    
    for(int idx = 0; idx < InpLookbackPoint; idx++)
    {
        if(m_lineTop[idx] != NULL) m_lineTop[idx].Delete();
        if(m_lineBottom[idx] != NULL) m_lineBottom[idx].Delete();
        if(m_recTop[idx] != NULL) m_recTop[idx].Delete();
        if(m_recBottom[idx] != NULL) m_recBottom[idx].Delete();
        m_lineTop[idx] =  NULL;
        m_lineBottom[idx] =  NULL;
        m_recTop[idx] =  NULL;
        m_recBottom[idx] = NULL;
        
        if(ObjectFind(0, "line_" + idx) >= 0)
            ObjectDelete(0, "line_" + idx);
        if(ObjectFind(0, "rec_" + idx) >= 0)
            ObjectDelete(0, "rec_" + idx);
    }
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Sự kiện được gọi mỗi khi có tín hiệu từ server                            |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
    // ----------------------------------------------------
    // Tính toán các giá trị cho chỉ báo zigzag
    int calculated = BarsCalculated(m_zigzagHandler);
    if(calculated < rates_total)
    {
        //Print("Not all data of zigzag is calculated (", calculated," bars). Error ", GetLastError());
        return(0);
    }
    
    int to_copy;
    // Thời điểm khởi đầu -> Copy hết dữ liệu
    if(prev_calculated > rates_total || prev_calculated <= 0)
    {
        to_copy = rates_total;
    }
    // Từ lần thứ 2 trở đi
    else
    {
        to_copy = rates_total - prev_calculated;
        if(prev_calculated > 0)
            to_copy++;
    }
    
    if(to_copy == 0)
        return rates_total;
    

    // Zigzag
    if(IsStopped()) // checking for stop flag
        return(0);
    if(CopyBuffer(m_zigzagHandler, 0, 0, to_copy, m_zigzagTopBuffer) <= 0)
    {
        Print("Getting zigzag top is failed! Error ", GetLastError());
        return(0);
    }
    if(CopyBuffer(m_zigzagHandler, 1, 0, to_copy, m_zigzagBottomBuffer) <= 0)
    {
        Print("Getting zigzag bottom is failed! Error ", GetLastError());
        return(0);
    }
    
    //Print("top=" + idxFirstTop + "; bottom=" + idxFirstBottom);
    //Print("time=" + time[rates_total - idxFirstTop - 1]);
    //DrawLine(m_lineTop1, 1, time[rates_total - idxFirstTop - 1], m_zigzagTopBuffer[idxFirstTop],
    //                        time[rates_total - 1], m_zigzagTopBuffer[idxFirstTop]);
    
    int idxTops[], idxBottoms[];
    ArrayResize(idxTops, InpLookbackPoint);
    ArrayResize(idxBottoms, InpLookbackPoint);
    
    int idxFindTop = 4;
    int idxFindBottom = 4;
    for(int idx = 0; idx < InpLookbackPoint; idx++)
    {
        idxFindTop = GetFirstPoint(m_zigzagTopBuffer, idxFindTop + 1);
        idxFindBottom = GetFirstPoint(m_zigzagBottomBuffer, idxFindBottom + 1);
        idxTops[idx] = idxFindTop;
        idxBottoms[idx] = idxFindBottom;
        
        //DrawRec(m_recTop[idx-1], idx, 
        //        time[rates_total - idxFindTop - 1], m_zigzagTopBuffer[idxFindTop],
        //        time[rates_total - 1], m_zigzagTopBuffer[idxFindTop] - PointsToPriceShift(_Symbol, 150));
    }
    CArrayList<int> lstExcludeTop;
    CArrayList<int> lstExcludeBottom;
    int bufferPoints = InpZone;
    for(int idx = InpLookbackPoint - 1; idx >= 0; idx--)
    {
        bool hasDrawRecTop = false, hasDrawRecBottom = false;
        datetime time1Top = time[rates_total - idxTops[idx] - 1];
        datetime time1Bottom = time[rates_total - idxBottoms[idx] - 1];
        datetime time2 = time[rates_total - 1];
        time2 += PeriodSeconds(PERIOD_CURRENT)*5;
        
        double maxTopPrice = -1;
        double minBottomPrice = -1;
        
        double bufferCheck = PointsToPriceShift(_Symbol, bufferPoints);
        //Print("Found idxTop=" + idxTops[idx]);
        for(int idxCheck = idx - 1; idxCheck >= 0; idxCheck--)
        {
            if(MathAbs(m_zigzagTopBuffer[idxTops[idx]] - m_zigzagTopBuffer[idxTops[idxCheck]]) <= bufferCheck)
            {
                if(lstExcludeTop.IndexOf(idxTops[idx], 0) < 0)
                {
                    if(maxTopPrice < m_zigzagTopBuffer[idxTops[idxCheck]])
                        maxTopPrice = m_zigzagTopBuffer[idxTops[idxCheck]];
                    
                    lstExcludeTop.Add(idxTops[idxCheck]);
                    hasDrawRecTop = true;
                }
                
                //break;
            }
            
            if(MathAbs(m_zigzagBottomBuffer[idxBottoms[idx]] - m_zigzagBottomBuffer[idxBottoms[idxCheck]]) <= bufferCheck)
            {
                
                if(lstExcludeBottom.IndexOf(idxBottoms[idx]) < 0)
                {
                    if(minBottomPrice > m_zigzagBottomBuffer[idxBottoms[idxCheck]] || minBottomPrice < 0)
                        minBottomPrice = m_zigzagBottomBuffer[idxBottoms[idxCheck]];
                    
                    lstExcludeBottom.Add(idxBottoms[idxCheck]);
                    hasDrawRecBottom = true;
                }
                //break;
            }
        }
        if(!hasDrawRecTop)
        {
            if(lstExcludeTop.IndexOf(idxTops[idx]) < 0)
            {
                datetime time1 = time[rates_total - idxTops[idx] - 1];
                datetime time2 = time[rates_total - 1];
                time2 += PeriodSeconds(PERIOD_CURRENT)*5;
                DrawLine(m_lineTop[idx], "line_" + idx, 
                            time1, m_zigzagTopBuffer[idxTops[idx]],
                            time2, m_zigzagTopBuffer[idxTops[idx]]);
            }
        }
        else
        {
            DrawRec(m_recTop[idx], "rec_" + idx, 
                    time1Top, m_zigzagTopBuffer[idxTops[idx]],
                    time2, maxTopPrice,
                    clrDarkGoldenrod);
        }
        if(!hasDrawRecBottom)
        {
            if(lstExcludeBottom.IndexOf(idxBottoms[idx]) < 0)
            {
                datetime time1 = time[rates_total - idxBottoms[idx] - 1];
                datetime time2 = time[rates_total - 1];
                time2 += PeriodSeconds(PERIOD_CURRENT)*5;
                DrawLine(m_lineBottom[idx], "line_" + idx, 
                            time1, m_zigzagBottomBuffer[idxBottoms[idx]],
                            time2, m_zigzagBottomBuffer[idxBottoms[idx]]);
            }
        }
        else
        {
            DrawRec(m_recBottom[idx], "rec_" + idx, 
                    time1Bottom, m_zigzagBottomBuffer[idxBottoms[idx]],
                    time2, minBottomPrice,
                    clrDarkSeaGreen);
                    
        }
    }
    return rates_total;
}
