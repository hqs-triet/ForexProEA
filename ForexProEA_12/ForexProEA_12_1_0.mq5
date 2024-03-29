#property description "This is demo EA for lessons on learning group."
#property copyright "ForexProEA"
#property link "https://www.facebook.com/groups/forexproea/"
#property version   "12.10"

// Mã số định danh cho EA (để phân biệt với các EA khác)
#define MAGIC_NUMBER 10001210

#include <trade/trade.mqh>
#include <expert/expertbase.mqh>
#include  "..\libs\ExpertWrapper.mqh"

#include  "..\libs\Common.mqh"
#include  "..\libs\PriceAction.mqh"
#include  "..\libs\CLineH.mqh"
#include  "..\libs\BuySellDialog.mqh"
// ===================================================================
// Tham số đầu vào của EA [start]
// ===================================================================

// ===================================================================
// Tham số đầu vào của EA [ end ]
// ===================================================================


// ===================================================================
// Khai báo các đối tượng cục bộ [start]
// ===================================================================
// Sử dụng đối tượng để thao tác mở lệnh trong EA
CTrade        m_trader;
// Đối tượng truy xuất thông tin giá
AllSeriesInfo m_infoCurrency;

// Thông tin chung
string m_symbolCurrency;    // Cặp tiền tệ đang trade
ENUM_TIMEFRAMES m_tf;       // Khung thời gian đang trade
int m_prevCalculated;       // Lưu số lượng nến trước đó, dùng để tính số lượng nến phát sinh
int m_limit;                // Lưu số lượng nến phát sinh động

const string CONST_ENTRY_ID = "entry001";
const string CONST_ENTRY_TEXT = "Entry";
const string CONST_SL_ID = "sl001";
const string CONST_SL_TEXT = "SL";
const string CONST_TP_ID = "tp001";
const string CONST_TP_TEXT = "TP";

CLineH *m_lineEntry, *m_lineSL, *m_lineTP;
CControlsDialog *ExtDialog;
// ===================================================================
// Khai báo các đối tượng cục bộ [ end ]
// ===================================================================


//+------------------------------------------------------------------+
// Khởi tạo các thông số cho chiến thuật
//+------------------------------------------------------------------+
int Init(string symbol, ENUM_TIMEFRAMES tf)
{
    // Lưu các tham số khởi tạo
    m_symbolCurrency = symbol;
    m_tf = tf;
    // Khởi tạo đối tượng thao tác mở lệnh
    m_trader.SetExpertMagicNumber(MAGIC_NUMBER); // Số định danh
    m_trader.SetMarginMode();
    m_trader.SetTypeFillingBySymbol(m_symbolCurrency);
    
    // Khởi tạo đối tượng thao tác giá
    m_infoCurrency.init(m_symbolCurrency, m_tf);
    
    // ===================================================================
    
    // Khởi tạo các đối tượng đồ trên biểu đồ
    if(m_lineEntry == NULL)
        m_lineEntry = new CLineH();
    else
        m_lineEntry.Probe(CONST_ENTRY_ID);
    
    if(m_lineSL == NULL)
        m_lineSL = new CLineH();
    else
        m_lineSL.Probe(CONST_SL_ID);

    if(m_lineTP == NULL)
        m_lineTP = new CLineH();
    else
        m_lineTP.Probe(CONST_TP_ID);
        
    // ===================================================================
    // Khởi tạo bảng điều khiển
    // ===================================================================
    ExtDialog = new CControlsDialog();
    if(!ExtDialog.Create(0,"Forex Pro EA - Bảng điều khiển",0, 
                         20, 20, 360, 324))
        return(INIT_FAILED);
    TAction onSell = OnSellCustom;
    TAction onBuy = OnBuyCustom;
    ExtDialog.SetActionButtonSell(onSell);
    ExtDialog.SetActionButtonBuy(onBuy);
    ExtDialog.Run();
    // ===================================================================
    
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
// Xử lý chính của chiến thuật
//+------------------------------------------------------------------+
void Process()
{
    // Xử lý các tác vụ chung
    ProcessCommon();
    
    // Đọc dữ liệu của các chỉ báo
    ReadIndicatorData();
    
    // Tiết kiệm CPU bằng cách chỉ xử lý khi có nến mới
    if(m_limit <= 0)
        return;

    // ===================================================================
    // Xử lý chính giao dịch [start]
    // ===================================================================
    
    // Vì EA này chỉ thao tác trên giao diện nên không cần khối này
    
    
    // ===================================================================
    // Xử lý chính giao dịch [ end ]
    // ===================================================================
}
//+------------------------------------------------------------------+
// Xử lý chung của chiến thuật mỗi khi sự kiện tick xuất hiện
//+------------------------------------------------------------------+
void ProcessCommon()
{
    // Cập nhật thông tin mới nhất của giá mỗi khi có tick
    m_infoCurrency.refresh();
    
    // Tính toán số lượng nến phát sinh
    int bars = Bars(m_symbolCurrency, m_tf);
    m_limit = bars - m_prevCalculated;
    m_prevCalculated = bars;
}

//+------------------------------------------------------------------+
// Đọc dữ liệu của các indicator
//+------------------------------------------------------------------+
void ReadIndicatorData()
{
    // Tính toán số lượng nến cần đọc
    int bars = Bars(m_symbolCurrency, m_tf);
    
}

//+------------------------------------------------------------------+
//| Khởi tạo ban đầu
//+------------------------------------------------------------------+
int OnInit()
{
    // Khởi tạo chung
    return Init(Symbol(), Period());
    
    return INIT_SUCCEEDED;
}
void OnDeinit(const int reason)
{
    // Hủy đối tượng: bảng điều khiển
    if(ExtDialog != NULL)
        ExtDialog.Destroy(reason);
}

//+------------------------------------------------------------------+
//| Sự kiện chính
//+------------------------------------------------------------------+
void OnTick()
{
    Process();
}


//+------------------------------------------------------------------+
//| Sự kiện trên biểu đồ
//+------------------------------------------------------------------+
void OnChartEvent(const int id,       // event id
                const long&   lparam, // chart period
                const double& dparam, // price
                const string& sparam  // symbol
               )
{
    // Xử lý sự kiện cho các controls
    ExtDialog.ProcessEvent(id,lparam,dparam,sparam);
    m_lineEntry.ProcessEvent(id, lparam, dparam, sparam);
    m_lineSL.ProcessEvent(id, lparam, dparam, sparam);
    m_lineTP.ProcessEvent(id, lparam, dparam, sparam);
    
    // Tính toán khối lượng lệnh giao dịch
    CalculateVol();
    
    // Tính toán tỉ lệ lợi nhuận
    if(m_lineEntry.ExistObject() && m_lineSL.ExistObject() && m_lineTP.ExistObject())
    {
        ExtDialog.RR(m_lineEntry.Price(), m_lineSL.Price(), m_lineTP.Price());
    }
    
    // Hiển thị Entry, SL, TP với ngữ cảnh phù hợp
    if(id == CHARTEVENT_CLICK && !ExtDialog.MouseInsideDialog())
    {
        datetime time;
        double price;
        int subwindow;
        ChartXYToTimePrice(0,lparam,dparam,subwindow,time,price);
        if(ExtDialog.CanDraw())
        {
            if(m_lineEntry != NULL && !m_lineEntry.ExistObject())
                m_lineEntry.Init(CONST_ENTRY_ID, CONST_ENTRY_TEXT, price, time);
            else if(m_lineSL != NULL && m_lineEntry.ExistObject() && !m_lineSL.ExistObject())
                m_lineSL.Init(CONST_SL_ID, CONST_SL_TEXT, price, time, clrRed);
            else if(m_lineTP != NULL && m_lineEntry.ExistObject() && m_lineSL.ExistObject() && !m_lineTP.ExistObject())
                m_lineTP.Init(CONST_TP_ID, CONST_TP_TEXT, price, time, clrGreen);
        }
    }
}

//+------------------------------------------------------------------+
// Sự kiện nút SELL trên bảng điều khiển
//+------------------------------------------------------------------+
void OnSellCustom()
{
    m_infoCurrency.refresh();
    
    double entry, sl, tp;
    if(m_lineEntry.ExistObject() && m_lineSL.ExistObject() && m_lineTP.ExistObject())
    {
        entry = m_lineEntry.Price();
        sl = m_lineSL.Price();
        tp = m_lineTP.Price();
    }
    else
    {
        return;
    }
    
    if(sl <= entry || tp >= entry)
        return;

    int slPoint = PriceShiftToPoints(m_symbolCurrency, MathAbs(entry - sl));
    double lot = PointsToLots(m_symbolCurrency, ExtDialog.Risk(), slPoint);
    
    if(lot <= 0)
        return;
        
    string orderType = "";
    if(entry > m_infoCurrency.bid())
    {
        orderType = "Sell limit";
    }
    else if(entry < m_infoCurrency.bid())
    {
        orderType = "Sell stop";
    }
    int result = MessageBox("** " + orderType + " **\nVui lòng xác nhận giao dịch?", NULL, MB_OKCANCEL);
    if( result == IDCANCEL)
        return;
        
    if(entry > m_infoCurrency.bid())
    {
        m_trader.SellLimit(lot, entry, m_symbolCurrency, sl, tp);
    }
    else if(entry < m_infoCurrency.bid())
    {
        m_trader.SellStop(lot, entry, m_symbolCurrency, sl, tp);
    }
        
}

//+------------------------------------------------------------------+
// Sự kiện nút BUY trên bảng điều khiển
//+------------------------------------------------------------------+
void OnBuyCustom()
{
    m_infoCurrency.refresh();
    
    double entry, sl, tp;
    if(m_lineEntry.ExistObject() && m_lineSL.ExistObject() && m_lineTP.ExistObject())
    {
        entry = m_lineEntry.Price();
        sl = m_lineSL.Price();
        tp = m_lineTP.Price();
    }
    else
    {
        return;
    }
    
    if(sl >= entry || tp <= entry)
        return;

    int slPoint = PriceShiftToPoints(m_symbolCurrency, MathAbs(entry - sl));
    double lot = PointsToLots(m_symbolCurrency, ExtDialog.Risk(), slPoint);
    
    if(lot <= 0)
        return;
    
    string orderType = "";
    if(entry < m_infoCurrency.ask())
    {
        orderType = "Buy limit";
    }
    else if(entry > m_infoCurrency.ask())
    {
        orderType = "Buy stop";
    }
    
    int result = MessageBox("** " + orderType + " **\nVui lòng xác nhận giao dịch?", NULL, MB_OKCANCEL);
    if( result == IDCANCEL)
        return;
        
    if(entry < m_infoCurrency.ask())
    {
        m_trader.BuyLimit(lot, entry, m_symbolCurrency, sl, tp);
    }
    else if(entry > m_infoCurrency.ask())
    {
        m_trader.BuyStop(lot, entry, m_symbolCurrency, sl, tp);
    }
}

//+------------------------------------------------------------------+
// Cập nhật khối lượng (volume) khi có SL
//+------------------------------------------------------------------+
void CalculateVol()
{
    double entry, sl, tp;
    if(m_lineEntry.ExistObject() && m_lineSL.ExistObject() && m_lineTP.ExistObject())
    {
        entry = m_lineEntry.Price();
        sl = m_lineSL.Price();
        tp = m_lineTP.Price();
    }
    else
    {
        ExtDialog.Volume(0);
        return;
    }
    
    int slPoint = PriceShiftToPoints(m_symbolCurrency, MathAbs(entry - sl));
    double lot = PointsToLots(m_symbolCurrency, ExtDialog.Risk(), slPoint);
    
    double slMoney = PointsToMoney(m_symbolCurrency, slPoint, lot);
    double tpMoney = slMoney * ExtDialog.RR();
    if(lot == 0)
    {
        slMoney = tpMoney = 0;
    }
    ExtDialog.Volume(lot);
    ExtDialog.SLMoney(slMoney);
    ExtDialog.TPMoney(tpMoney);
}