//+--------------------------------------------------------------------------+
//|                                           ForexProEA_6_6_MultipleSMA.mq5 |
//|                                                             Forex Pro EA |
//|                              https://www.facebook.com/groups/forexproea/ |
//+--------------------------------------------------------------------------+
#property copyright "Forex Pro EA"
#property link      "https://www.facebook.com/groups/forexproea/"
#property version   "1.00"

#include "..\\libs\\Common.mqh"
// Khai báo sử dụng chỉ báo chung với biểu đồ chính
#property indicator_chart_window
// Số lượng tối đa: 22 buffer (bao gồm tối đa 20 đường MA và 1 đường tín hiệu)
#property indicator_buffers 22
// Số lượng đường MA hiển thị tối đa là 21
#property indicator_plots 21

//-------------------------------------------------------------- 
// Thông tin thiết lập cho đường trung bình MA 1,2,3,...,20
//--------------------------------------------------------------
#property indicator_color1  clrYellow
#property indicator_type1  DRAW_LINE
#property indicator_style1  STYLE_SOLID

#property indicator_color2  clrOrange
#property indicator_type2  DRAW_LINE
#property indicator_style2  STYLE_SOLID

#property indicator_color3  clrSteelBlue
#property indicator_type3  DRAW_LINE
#property indicator_style3  STYLE_SOLID

#property indicator_color4  clrMediumOrchid
#property indicator_type4  DRAW_LINE
#property indicator_style4  STYLE_SOLID

#property indicator_color5  clrLimeGreen
#property indicator_type5  DRAW_LINE
#property indicator_style5  STYLE_SOLID

#property indicator_color6  clrBrown
#property indicator_type6  DRAW_LINE
#property indicator_style6  STYLE_SOLID

#property indicator_color7  clrDarkGray
#property indicator_type7  DRAW_LINE
#property indicator_style7  STYLE_SOLID

#property indicator_color8  clrBlueViolet
#property indicator_type8  DRAW_LINE
#property indicator_style8  STYLE_SOLID

#property indicator_color9  clrCyan
#property indicator_type9  DRAW_LINE
#property indicator_style9  STYLE_SOLID

#property indicator_color10  clrDarkBlue
#property indicator_type10  DRAW_LINE
#property indicator_style10  STYLE_SOLID

#property indicator_color11  clrWhiteSmoke
#property indicator_type11  DRAW_LINE
#property indicator_style11  STYLE_SOLID

#property indicator_color12  clrGray
#property indicator_type12  DRAW_LINE
#property indicator_style12  STYLE_SOLID

#property indicator_color13  clrBlanchedAlmond
#property indicator_type13  DRAW_LINE
#property indicator_style13  STYLE_SOLID

#property indicator_color14  clrAzure
#property indicator_type14  DRAW_LINE
#property indicator_style14  STYLE_SOLID

#property indicator_color15  clrCadetBlue
#property indicator_type15  DRAW_LINE
#property indicator_style15  STYLE_SOLID

#property indicator_color16  clrChocolate
#property indicator_type16  DRAW_LINE
#property indicator_style16  STYLE_SOLID

#property indicator_color17  clrGold
#property indicator_type17  DRAW_LINE
#property indicator_style17  STYLE_SOLID

#property indicator_color18  clrSilver
#property indicator_type18  DRAW_LINE
#property indicator_style18  STYLE_SOLID

#property indicator_color19  clrSlateGray
#property indicator_type19  DRAW_LINE
#property indicator_style19  STYLE_SOLID

#property indicator_color20  clrGreen
#property indicator_type20  DRAW_LINE
#property indicator_style20  STYLE_SOLID


//--------------------------------------------------------------
// Chỉ báo tín hiệu BUY/SELL, khi có tín hiệu
#property indicator_label21  "Fan signal"
// Chỉ định vẽ đường thẳng có màu
#property indicator_type21   DRAW_COLOR_ARROW
// Màu được định nghĩa theo một danh sách, đánh số từ 0, 1
#property indicator_color21  clrBlue, clrRed
#property indicator_width21  5
//--------------------------------------------------------------

//--------------------------------------------------------------
// Tham số đầu vào (input)
//--------------------------------------------------------------
input group "=== Thông số các đường trung bình MA ==="
input string InpMAPeriods = "4;8;12;16;20;24;28;32";    // Các đường MA cách nhau dấu ";" (tối đa 20)
input ENUM_MA_METHOD InpMAMethod = MODE_SMA;            // Phương thức hiển thị MA


input group "=== Thiết lập hiển thị ==="
input int InpMAShift = 0;           // Hiển thị dịch chuyển (shift)
input bool InpChangeColorOfCandle = false;  // Thay đổi màu của nến theo màu nền

//--------------------------------------------------------------


//-----------------------------------------------------------------------------------------------
// Khai báo cấu trúc lưu trữ bộ đệm là một mảng các giá trị double
// Và sau đó khai báo một mảng các đối tượng cấu trúc để lưu trữ mảng các bộ đệm
// Điều này tương tự như mảng 2 chiều:
//      double m_dataBuffer[][]
// Nhưng vì khi thiết lập liên kết với bộ đệm hiển thị, mảng 2 chiều không được cho phép.
// Cho nên giải pháp là sử dụng cấu trúc, bên trong lưu trữ bộ đệm liên kết hiển thị vào biểu đồ
// -----------------------------------------------------------------------------------------------
struct dataBuff {
    double data[];
};
dataBuff m_dataBuffer[];

// Lưu trữ danh sách các giai đoạn của các đường MA
int m_validMA[];

// Bộ đệm của đường tín hiệu khi các đường MA quạt lên/xuống, dùng cho tín hiệu BUY/SELL
double m_signalBuffer[],
       m_signalBufferColor[];   // Bộ đệm này được dùng để hiển thị màu của chỉ báo tín hiệu

//+------------------------------------------------------------------+
//| Sự kiện khởi tạo
//+------------------------------------------------------------------+
int OnInit()
{
    
    if(!ValidateMAs())
        return INIT_FAILED;
    
    
    // Thiết lập hiển thị chính xác số thập phân
    IndicatorSetInteger(INDICATOR_DIGITS, _Digits + 1);
    
    string short_name;
    switch(InpMAMethod)
    {
        case MODE_EMA :
            short_name="EMA";
            break;
        case MODE_LWMA :
            short_name="LWMA";
            break;
        case MODE_SMA :
            short_name="SMA";
            break;
        case MODE_SMMA :
            short_name="SMMA";
            break;
        default :
            short_name="unknown ma";
    }
    
    // Thiết lập các đường MA được chỉ định từ người dùng 
    for(int idx = 0; idx < ArraySize(m_validMA); idx++)
    {
        // Thiết lập mapping bộ đệm của biến lưu trữ với bộ đệm hiển thị lên biểu đồ
        SetIndexBuffer(idx, m_dataBuffer[idx].data, INDICATOR_DATA);
        
        // Di chuyển MA theo khoảng nến nhất định (shift)
        PlotIndexSetInteger(idx, PLOT_SHIFT, InpMAShift);
        
        // Với những vị trí không có giá trị, thiết lập giá trị 0.0
        PlotIndexSetDouble(idx, PLOT_EMPTY_VALUE, 0.0);
        
        // Tên của đường hiển thị
        string plotName = short_name + (string)(idx+1) + "(" + (string)m_validMA[idx] + ")";
        PlotIndexSetString(idx, PLOT_LABEL, plotName);
    }
    
    // Thiết lập bộ đệm cho chỉ báo tín hiệu và màu hiển thị
    SetIndexBuffer(20, m_signalBuffer, INDICATOR_DATA);
    SetIndexBuffer(21, m_signalBufferColor, INDICATOR_COLOR_INDEX);
    
    // Di chuyển đường tín hiệu theo khoảng nến nhất định (shift)
    PlotIndexSetInteger(20, PLOT_SHIFT, InpMAShift);
    
    // Với những vị trí không có giá trị, thiết lập giá trị 0.0
    PlotIndexSetDouble(20, PLOT_EMPTY_VALUE, 0.0);
    
    // Thiết lập kiểu vẽ của đường chỉ báo tín hiệu BUY/SELL
    // Giá trị code 159 theo font Wingdings là kiểu vẽ vòng tròn
    PlotIndexSetInteger(20, PLOT_ARROW, 159);
    
    // Thiết lập màu của nến theo màu nền của biểu đồ
    // Lúc này, người dùng sẽ tập trung vào các đường MA mà không quan tâm tới nến
    if(InpChangeColorOfCandle)
    {
        long bgColor = ChartGetInteger(0, CHART_COLOR_BACKGROUND);
        ChartSetInteger(0, CHART_COLOR_CANDLE_BULL, bgColor);
        ChartSetInteger(0, CHART_COLOR_CANDLE_BEAR, bgColor);
        ChartSetInteger(0, CHART_COLOR_CHART_DOWN, bgColor);
        ChartSetInteger(0, CHART_COLOR_CHART_UP, bgColor);
        ChartSetInteger(0, CHART_COLOR_CHART_LINE, bgColor);
    }
    
    return(INIT_SUCCEEDED);
}

// ------------------------------------------------
// Kiểm tra tham số MA được nhập vào từ người dùng
// ------------------------------------------------
bool ValidateMAs()
{
    string arrPeriods[];
    Split(InpMAPeriods, ";", arrPeriods);
    int arrMA[];
    CastArrayToInt(arrPeriods, arrMA);
    ArraySort(arrMA);
    
    
    int countValidMA = 0;
    for(int idx = 0; idx < ArraySize(arrMA); idx++)
    {
        if(arrMA[idx] > 0)
            countValidMA++;
    }
    ArrayResize(m_validMA, countValidMA);
    ArrayResize(m_dataBuffer, countValidMA);
    countValidMA = 0;
    for(int idx = 0; idx < ArraySize(arrMA); idx++)
    {
        if(arrMA[idx] > 0)
            m_validMA[countValidMA++] = arrMA[idx];
    }
    
    if(ArraySize(m_validMA) == 0)
    {
        Print("Lỗi! Vui lòng kiểm tra lại tham số đầu vào MA.");
        return false;
    }
    if(ArraySize(m_validMA) > 20)
    {
        Print("Lỗi! Chỉ hiển thị tối đã 20 đường MA");
        return false;
    }
    return true;
}

//+------------------------------------------------------------------+
//| Sự kiện được gọi mỗi khi có tín hiệu từ server                            |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const int begin,            // Đây là vị trí bắt đầu trong mảng price[] có dữ liệu đúng
                const double &price[])      // Đây là bộ đệm giá được truyền vào từ bảng thiết lập
{
    // Tính toán trung bình cộng tương ứng với từng MA
    for(int idx = 0; idx < ArraySize(m_validMA); idx++)
    {
        switch(InpMAMethod)
        {
            case MODE_EMA:
                CalculateEMA(rates_total, prev_calculated, begin, price, m_dataBuffer[idx].data, m_validMA[idx]);
                break;
            case MODE_LWMA:
                CalculateLWMA(rates_total, prev_calculated, begin, price, m_dataBuffer[idx].data, m_validMA[idx]);
                break;
            case MODE_SMMA:
                CalculateSmoothedMA(rates_total, prev_calculated, begin, price, m_dataBuffer[idx].data, m_validMA[idx]);
                break;
            case MODE_SMA:
                CalculateSMA(rates_total, prev_calculated, begin, price, m_dataBuffer[idx].data, m_validMA[idx]);
                break;
        }
        
    }    
    // ----------------------------------------------------
    // Tính toán các giá trị cho chỉ báo tín hiệu BUY/SELL
    if(prev_calculated == 0)
    {
        for(int idx = 1; idx < rates_total - 1; idx++)
        {
            if(IsFanDown(idx) || IsFanUp(idx))
            {
                m_signalBuffer[idx] = price[idx];
            }
            else
                m_signalBuffer[idx] = 0;
            
            if(IsFanDown(idx))
                m_signalBufferColor[idx] = 1;
            if(IsFanUp(idx))
                m_signalBufferColor[idx] = 0;
        }
    }
    else
    {
        m_signalBuffer[rates_total - 1] = 0;
        for(int idx = prev_calculated - 1; idx < rates_total - 1 && !IsStopped(); idx++)
        {
            if(IsFanDown(idx) || IsFanUp(idx))
                m_signalBuffer[idx] = price[idx];
            else
                m_signalBuffer[idx] = 0;
            
            if(IsFanDown(idx))
                m_signalBuffer[idx] = 1;
            if(IsFanUp(idx))
                m_signalBufferColor[idx] = 0;
        }
    }
    
    return rates_total;
}

//+------------------------------------------------------------------+
// Tính toán trung bình cộng SMA (Simple MA)
//+------------------------------------------------------------------+
void CalculateSMA(int rates_total, int prev_calculated, int begin, 
                   const double &price[],
                   double &dataBuffer[], int period)
{
    int start;
    // Lần đầu tiên tính toán dữ liệu của chỉ báo
    // Lúc này, giá trị prev_calculated <= 0
    if(prev_calculated <= 0)
    {
        // Giá trị start cần bắt đầu tính toán (bỏ qua 1 khoảng nến đầu tiên)
        start = period + begin;
        
        // Trong khoảng nến đầu tiên cần phải tính giá trung bình, 
        // nên giá trị của bộ đệm MA sẽ thiết lập là 0
        for(int idx = 0; idx < start - 1; idx++)
            dataBuffer[idx] = 0.0;
                
            
        // Tính toán giá trị trung bình đầu tiên
        double firstPriceSum = 0;
        for(int idx = begin; idx < start; idx++)
            firstPriceSum += price[idx];

        // Tính trung bình cho giá trị MA đầu tiên
        dataBuffer[start - 1] = firstPriceSum / period;
    }
    // Từ lần thứ 2 trở đi
    // Giá trị prev_calculated > 0
    else
        start = prev_calculated - 1;
        
    // Công đoạn này tính các vị trí tiếp theo
    // Lưu ý: cách này không tính tổng lại các nến giống như giá trị MA đầu tiên
    //        điều này sẽ tăng tốc độ xử lý, và việc tính toán hiệu quả hơn
    for(int idx = start; idx < rates_total && !IsStopped(); idx++)
        dataBuffer[idx] = dataBuffer[idx-1] + (price[idx] - price[idx - period]) / period;
}

//+------------------------------------------------------------------+
// Tính toán trung bình động EMA (Exponent MA)
//+------------------------------------------------------------------+
void CalculateEMA(int rates_total,int prev_calculated, int begin,
                  const double &price[], 
                  double &dataBuffer[], int period)
{
    int start;
    double SmoothFactor = 2.0 / (1.0 + period);
    // Lần đầu tiên tính toán dữ liệu của chỉ báo
    // Lúc này, giá trị prev_calculated <= 0
    if(prev_calculated == 0)
    {
        // Giá trị start cần bắt đầu tính toán (bỏ qua 1 khoảng nến đầu tiên)
        start = period + begin;
        
        // Tính toán giá trị trung bình đầu tiên
        dataBuffer[begin] = price[begin];
        for(int idx = begin + 1; idx < start; idx++)
            dataBuffer[idx] = price[idx] * SmoothFactor + dataBuffer[idx - 1] * (1.0 - SmoothFactor);
    }
    // Từ lần thứ 2 trở đi
    // Giá trị prev_calculated > 0
    else
        start = prev_calculated - 1;
        
    // Công đoạn này tính các vị trí tiếp theo
    // Lưu ý: cách này không tính tổng lại các nến giống như giá trị MA đầu tiên
    //        điều này sẽ tăng tốc độ xử lý, và việc tính toán hiệu quả hơn
    for(int idx = start; idx < rates_total && !IsStopped(); idx++)
        dataBuffer[idx] = price[idx] * SmoothFactor + dataBuffer[idx - 1] * (1.0 - SmoothFactor);
}

//+------------------------------------------------------------------+
//|  Tính toán đường trung bình động LWMA (Linear weighted MA)                                  |
//+------------------------------------------------------------------+
void CalculateLWMA(int rates_total,int prev_calculated,int begin,
                   const double &price[],
                   double &dataBuffer[], int period)
{
    int    weight = 0;
    int    i,l, start;
    double sum = 0.0, lsum = 0.0;
    
    // Lần đầu tiên tính toán dữ liệu của chỉ báo
    // Lúc này, giá trị prev_calculated <= 0
    if(prev_calculated <= period + begin + 2)
    {
        start= period + begin;
        // Trong khoảng nến đầu tiên cần phải tính giá trung bình, 
        // nên giá trị của bộ đệm MA sẽ thiết lập là 0
        for(i = 0; i< start; i++)
            dataBuffer[i] = 0.0;
    }
    else
      start = prev_calculated - 1;

    for(i = start - period , l = 1; i < start; i++, l++)
    {
        sum   += price[i]*l;
        lsum  += price[i];
        weight += l;
    }
    dataBuffer[start - 1] = sum / weight;

    // Công đoạn này tính các vị trí tiếp theo
    // Lưu ý: cách này không tính tổng lại các nến giống như giá trị MA đầu tiên
    //        điều này sẽ tăng tốc độ xử lý, và việc tính toán hiệu quả hơn
    for(i = start; i < rates_total && !IsStopped(); i++)
    {
        sum           = sum - lsum + price[i] * period;
        lsum          = lsum - price[i - period] + price[i];
        dataBuffer[i] = sum / weight;
    }
}
//+------------------------------------------------------------------+
//|  Tính toán đường trung bình động Smooth MA                                  |
//+------------------------------------------------------------------+
void CalculateSmoothedMA(int rates_total,int prev_calculated,int begin,
                         const double &price[],
                         double &dataBuffer[], int period)
{
    int i,start;

    // Lần đầu tiên tính toán dữ liệu của chỉ báo
    // Lúc này, giá trị prev_calculated <= 0
    if(prev_calculated == 0)
    {
        start = period + begin;
        // Trong khoảng nến đầu tiên cần phải tính giá trung bình, 
        // nên giá trị của bộ đệm MA sẽ thiết lập là 0
        for(i = 0; i < start - 1; i++)
            dataBuffer[i] = 0.0;
      
        // Tính toán giá trị trung bình đầu tiên
        double first_value = 0;
        for(i = begin; i < start; i++)
            first_value += price[i];
        first_value /= period;
        dataBuffer[start - 1] = first_value;
    }
    else
        start = prev_calculated - 1;

    // Công đoạn này tính các vị trí tiếp theo
    // Lưu ý: cách này không tính tổng lại các nến giống như giá trị MA đầu tiên
    //        điều này sẽ tăng tốc độ xử lý, và việc tính toán hiệu quả hơn
    for(i = start; i < rates_total && !IsStopped(); i++)
        dataBuffer[i] = (dataBuffer[i - 1] * (period - 1) + price[i]) / period;
}


//+------------------------------------------------------------------+
// Kiểm tra tại vị trí chỉ định xem MA có quạt lên không
//+------------------------------------------------------------------+
bool IsFanUp(int idx)
{
    if(idx == 0)
        return false;
        
    for(int i = 0; i < ArraySize(m_validMA) - 1; i++)
    {
        if(m_dataBuffer[i].data[idx] <= m_dataBuffer[i + 1].data[idx])
            return false;
    }
    
    bool isPrevOK = false;
    for(int i = 0; i < ArraySize(m_validMA) - 1; i++)
    {
        if(m_dataBuffer[i].data[idx - 1] <= m_dataBuffer[i + 1].data[idx - 1])
        {
            isPrevOK = true;
            break;
        }
    }
    return isPrevOK;
}

//+------------------------------------------------------------------+
// Kiểm tra tại vị trí chỉ định xem MA có quạt xuống không
//+------------------------------------------------------------------+
bool IsFanDown(int idx)
{
    if(idx == 0)
        return false;
        
    for(int i = 0; i < ArraySize(m_validMA) - 1; i++)
    {
        if(m_dataBuffer[i].data[idx] >= m_dataBuffer[i + 1].data[idx])
            return false;
    }
    
    bool isPrevOK = false;
    for(int i = 0; i < ArraySize(m_validMA) - 1; i++)
    {
        if(m_dataBuffer[i].data[idx - 1] >= m_dataBuffer[i + 1].data[idx - 1])
        {
            isPrevOK = true;
            break;
        }
    }
    return isPrevOK;
}

