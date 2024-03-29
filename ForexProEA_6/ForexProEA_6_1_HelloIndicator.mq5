//+------------------------------------------------------------------+
//|                                ForexProEA_6_1_HelloIndicator.mq5 |
//|                                                     Forex Pro EA |
//|                      https://www.facebook.com/groups/forexproea/ |
//+------------------------------------------------------------------+
#property copyright "Forex Pro EA"
#property link      "https://www.facebook.com/groups/forexproea/"
#property version   "1.00"

// Khai báo sử dụng chỉ báo ở một cửa sổ riêng
#property indicator_separate_window
#property indicator_buffers 1
#property indicator_plots   1

//--- plot Label1
#property indicator_label1  "Label1"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrRed
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1

//--- indicator buffers
double         Label1Buffer[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,Label1Buffer,INDICATOR_DATA);
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
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
//---
    // Lần đầu tiên tính toán dữ liệu của chỉ báo
    // Lúc này, giá trị prev_calculated <= 0
    if(prev_calculated <= 0)
        for(int idx = 0; idx < rates_total - 1 && !IsStopped(); idx++)
            Label1Buffer[idx] = (close[idx] - open[idx]) / 2;
    // Từ lần thứ 2 trở đi
    // Giá trị prev_calculated > 0
    else
        Label1Buffer[rates_total - 1] = (close[rates_total - 1] - open[rates_total - 1]) / 2;
        
    // Theo luồng xử lý của chỉ báo, thì giá trị trả về sẽ được truyền vào tham số prev_calculated cho lần gọi hàm tiếp theo 
    return(rates_total);
  }
//+------------------------------------------------------------------+
