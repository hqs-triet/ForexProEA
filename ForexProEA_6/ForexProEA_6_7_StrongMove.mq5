//+-------------------------------------------------------------------------+
//|                                           ForexProEA_6_7_StrongMove.mq5 |
//|                                                            Forex Pro EA |
//|                             https://www.facebook.com/groups/forexproea/ |
//+-------------------------------------------------------------------------+
#property copyright "Forex Pro EA"
#property link      "https://www.facebook.com/groups/forexproea/"
#property version   "1.00"
#property description "The strong-move signal!"

// Khai báo thư viện ve biểu tượng trên biểu đồ
#include <ChartObjects\ChartObjectsArrows.mqh>
#include  "..\\libs\Common.mqh"

// Khai báo sử dụng chỉ báo chung với biểu đồ chính
#property indicator_chart_window
// Tổng số bộ đệm
#property indicator_buffers 5
// Chỉ định tổng số đường hiển thị
#property indicator_plots   3

//--------------------------------------------------------------
// Chỉ báo tín hiệu BUY/SELL
#property indicator_label1  "Signal buy"
#property indicator_type1   DRAW_ARROW
#property indicator_color1  clrYellow
#property indicator_width1  10

#property indicator_label2  "Signal sell"
#property indicator_type2   DRAW_ARROW
#property indicator_color2  clrYellow
#property indicator_width2  10

// Chỉ báo tín hiệu cắt lệnh
#property indicator_label3  "Signal cut"
#property indicator_type3   DRAW_ARROW
#property indicator_color3  clrWhite
#property indicator_width3  10
//--------------------------------------------------------------

//--------------------------------------------------------------
// Tham số đầu vào (input)
//--------------------------------------------------------------
input int InpSidewayPeriod = 40;                        // Sideway periods
input ENUM_APPLIED_PRICE InpAppliedPrice = PRICE_CLOSE; // Applied price
input int InpMAShift = 0;                               // Shift

input bool InpDrawSymbol = false;                       // Draw symbol BUY/SELL
input bool InpShowAlert = false;                        // Show alert
input bool InpSendNotification = false;                 // Send notification


//--------------------------------------------------------------
// Bộ đệm hiển thị
double m_signalBuyBuffer[], m_signalSellBuffer[], m_signalCutBuffer[],    // Bộ đệm của đường tín hiệu BUY/SELL
       m_rsiBuffer[],
       m_adxBuffer[];

// Cờ điều khiển đọc chỉ báo rsi và adx
int m_rsiHandler, m_adxHandler;
int m_symbolId;

//+------------------------------------------------------------------+
//| Sự kiện khởi tạo
//+------------------------------------------------------------------+
int OnInit()
{
    // Thiết lập mapping bộ đệm của biến lưu trữ với bộ đệm hiển thị lên biểu đồ
    SetIndexBuffer(0, m_signalBuyBuffer, INDICATOR_DATA);
    SetIndexBuffer(1, m_signalSellBuffer, INDICATOR_DATA);
    SetIndexBuffer(2, m_signalCutBuffer, INDICATOR_DATA);
    
    SetIndexBuffer(3, m_rsiBuffer, INDICATOR_CALCULATIONS);
    SetIndexBuffer(4, m_adxBuffer, INDICATOR_CALCULATIONS);
    
    // Thiết lập hiển thị chính xác số thập phân
    IndicatorSetInteger(INDICATOR_DIGITS, _Digits + 1);
    
    // Thiết lập kiểu vẽ của đường chỉ báo tín hiệu BUY/SELL
    // Giá trị code 159 theo font Wingdings là kiểu vẽ vòng tròn
    PlotIndexSetInteger(0, PLOT_ARROW, 159);
    PlotIndexSetInteger(1, PLOT_ARROW, 159);
    PlotIndexSetInteger(2, PLOT_ARROW, 159);
    
    // Di chuyển SMA theo khoảng nến nhất định (shift)
    PlotIndexSetInteger(0, PLOT_SHIFT, InpMAShift);
    PlotIndexSetInteger(1, PLOT_SHIFT, InpMAShift);
    PlotIndexSetInteger(2, PLOT_SHIFT, InpMAShift);
    
    // Với những vị trí không có giá trị, thiết lập giá trị 0.0
    PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, 0.0);
    PlotIndexSetDouble(1, PLOT_EMPTY_VALUE, 0.0);
    PlotIndexSetDouble(2, PLOT_EMPTY_VALUE, 0.0);
    
    // Khởi tạo sử dụng chỉ báo RSI và ADX
    m_rsiHandler = iRSI(NULL, 0, 14, InpAppliedPrice);
    m_adxHandler = iADXWilder(NULL, 0, 14);
    
    // Khởi tạo id cho việc vẽ biểu tượng BUY/SELL
    m_symbolId = 0;

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
    // Tính toán các giá trị cho chỉ báo RSI, ADX
    int calculated = BarsCalculated(m_rsiHandler);
    if(calculated < rates_total)
    {
        Print("Not all data of RSI is calculated (", calculated," bars). Error ", GetLastError());
        return(0);
    }
    calculated = BarsCalculated(m_adxHandler);
    if(calculated < rates_total)
    {
        Print("Not all data of ADX is calculated (", calculated," bars). Error ", GetLastError());
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
    

    // RSI
    if(IsStopped()) // checking for stop flag
        return(0);
    if(CopyBuffer(m_rsiHandler, 0, 0, to_copy, m_rsiBuffer) <= 0)
    {
        Print("Getting RSI is failed! Error ", GetLastError());
        return(0);
    }
    
    // ADX
    if(IsStopped()) // checking for stop flag
        return(0);
    if(CopyBuffer(m_adxHandler, 0, 0, to_copy, m_adxBuffer) <= 0)
    {
        Print("Getting ADX is failed! Error ", GetLastError());
        return(0);
    }
    
    int start;
    if(prev_calculated == 0)
    {
        start = 0;
        // Bỏ qua vị trí nến hiện tại (mới nhất)
        m_signalBuyBuffer[rates_total - 1] = 0;
        m_signalSellBuffer[rates_total - 1] = 0;
        m_signalCutBuffer[rates_total - 1] = 0;
    }
    else
        start = prev_calculated - 1;
    
    // Vòng lặp chính duyệt qua các nến để xử lý tín hiệu BUY/SELL/CUT
    for(int i = start; i < rates_total - 1 && !IsStopped(); i++)
    {
        //MqlDateTime currTime;
        //TimeToStruct(time[i], currTime);
        
        m_signalBuyBuffer[i] = 0;
        m_signalSellBuffer[i] = 0;
        m_signalCutBuffer[i] = 0;
        
        // ----------------------------------------------------------
        // Hiển thị tín hiệu xu hướng kết thúc
        if(i > 2)
            if(m_adxBuffer[i] < 35 && m_adxBuffer[i-1] > 35)
            {   
                // Tìm tín hiệu BUY/SELL trước đó
                // Nếu tồn tại thì hiển thị tín hiệu: kết thúc xu hướng
                bool foundSingalBuySell = false;
                for(int j = i - 2; j > 1; j--)
                {
                    if(m_signalCutBuffer[j] > 0)
                        break;
                        
                    // Giảm
                    if(m_signalSellBuffer[j] > 0 || m_signalBuyBuffer[j] > 0)
                    {
                        foundSingalBuySell = true;
                        break;
                    }
                }
                
                if(foundSingalBuySell)
                {
                    m_signalCutBuffer[i] = close[i];
                    
                    // Trường hợp này không dành cho thời điểm khởi tạo chỉ báo
                    if(prev_calculated > 0)
                    {
                        string msg = "[" + _Symbol + "-" + EnumToString(Period()) + "]: The strength of signal in ending!";
                        if(InpShowAlert)
                            Alert(msg);
                        if(InpSendNotification)
                            SendNotification(msg);
                    }
                    continue;
                }
            }
        //----------------------------------------------------------
        
        // Đếm số lượng nến có RSI trong phạm vi 30~70 
        int maxCount = InpSidewayPeriod;
        
        if(i < maxCount)
            continue;
        
        int countSidewayAdx = maxCount;
        int countSidewayForBuy = maxCount;
        int countSidewayForSell = maxCount;
        for(int idxSw = maxCount; idxSw >= 1; idxSw--)
        {
            if(m_rsiBuffer[i - idxSw] > 70)
                countSidewayForBuy--;
            if(m_rsiBuffer[i - idxSw] < 30)
                countSidewayForSell--;
            if(m_adxBuffer[i - idxSw] > 25)
                countSidewayAdx--;
        }
        
        // Chỉ cho phép 5 nến vượt ngoài phạm vi 30~70
        if(countSidewayForBuy < maxCount && countSidewayForSell < maxCount)
            continue;
            
        if(countSidewayForBuy <= maxCount - 5 || countSidewayForSell <= maxCount - 5)
            continue;
        
        //if(countSidewayAdx <= maxCount - 5)
        //    continue;
            
        // Nếu trong phạm vi 6 nến trước đó có tồn tại tín hiệu BUY/SELL/CUT thì bỏ qua
        if(i > 5)
        {
            bool canNextProcess = true;
            for(int k = 1; k <= 6; k++)
            {
                if(m_signalBuyBuffer[i - k] > 0 
                   || m_signalSellBuffer[i - k] > 0
                   || m_signalCutBuffer[i - k] > 0)
                   canNextProcess = false;
            }
            if(!canNextProcess)
                continue;
        }
        
        // Điều kiện BUY:
        // . RSI > 70
        // . ADX > 25
        // . ADX <= 35
        if(m_rsiBuffer[i] > 70 && m_adxBuffer[i] > 25
                               && m_adxBuffer[i] <= 35
                               && countSidewayForSell == maxCount)
        {
            m_signalBuyBuffer[i] = close[i];
            if(prev_calculated > 0)
            {
                string msg = _Symbol + "Beginning the signal of BUY!";
                if(InpShowAlert)
                    Alert(msg);
                if(InpSendNotification)
                    SendNotification(msg);
                if(InpDrawSymbol)
                    DrawSymbolBuy(close[i]);
            }
        }
        
        // Điều kiện SELL:
        // . RSI < 30
        // . ADX > 25
        // . ADX <= 35
        if(m_rsiBuffer[i] < 30 && m_adxBuffer[i] > 25
                               && m_adxBuffer[i] <= 35
                               && countSidewayForBuy == maxCount)
        {
            m_signalSellBuffer[i] = close[i];
            if(prev_calculated > 0)
            {
                string msg = _Symbol + "Beginning the signal of SELL!";
                if(InpShowAlert)
                    Alert(msg);
                if(InpSendNotification)
                    SendNotification(msg);
                if(InpDrawSymbol)
                    DrawSymbolSell(close[i]);
            }
        }
            
    }
    return rates_total;
}


//+------------------------------------------------------------------+
// Vẽ biểu tượng SELL
//+------------------------------------------------------------------+
void DrawSymbolSell(double price)
{
    CChartObjectArrow *sym = new CChartObjectArrow();
    
    datetime date1 = TimeCurrent();
    // 217: up
    // 218: down
    // 82: sunshine
    // 181: star
    ++m_symbolId;
    char symCode = (char)218;
    sym.Create(0, "sym_" + IntegerToString(m_symbolId), 0, date1, price, symCode);
    sym.Color(clrWhite);
    sym.Selectable(true);
    sym.Anchor(ANCHOR_BOTTOM);
}
void DrawSymbolBuy(double price)
{
    CChartObjectArrow *sym = new CChartObjectArrow();
    
    datetime date1 = TimeCurrent();
    // 217: up
    // 218: down
    // 82: sunshine
    // 181: star
    ++m_symbolId;
    char symCode = (char)217;
    sym.Create(0, "sym_" + IntegerToString(m_symbolId), 0, date1, price, symCode);
    sym.Color(clrWhite);
    sym.Selectable(true);
    sym.Anchor(ANCHOR_TOP);
}