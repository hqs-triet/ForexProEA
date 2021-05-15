#property description "Quản lý vốn theo phương pháp Hedge"
#property copyright "ForexProEA"
#property link "https://www.facebook.com/groups/forexproea/"
#property version   "12.71"

// Mã số định danh cho EA (để phân biệt với các EA khác)
#define MAGIC_NUMBER 10001270

#include <trade/trade.mqh>
#include <expert/expertbase.mqh>
#include  "..\libs\ExpertWrapper.mqh"
#include  "..\libs\Common.mqh"
#include  "..\libs\Hedge.mqh"
#include  "..\libs\Algorithm\GuiTrade.mqh"

// ===================================================================
// Tham số đầu vào của EA [start]
// ===================================================================
input string InpCommentPlus = "hedge";  // Ghi chú thêm vào mỗi lệnh

input group "Trade tự động"
input bool InpAutoTrade = false;     // Dùng chức năng trade tự động
input bool InpAutoTrade_UseRandomAlgo = false;  // *** Chiến thuật: mở lệnh ngẫu nhiên
input ENUM_TIMEFRAMES InpRandomAlgoTF = PERIOD_CURRENT;    // |- Khung thời gian
#include  "..\libs\Algorithm\Random.mqh"

input bool InpAutoTrade_UseAdxBBEm200Algo = false;  // *** Chiến thuật M5, M15: dùng ADX+BB+EMA200
input ENUM_TIMEFRAMES InpAdxBBEm200AlgoTF = PERIOD_M5;    // |- Khung thời gian
#include  "..\libs\Algorithm\AdxBBEma200.mqh"

input bool InpAutoTrade_UseEma10Ema20Ema200Algo = false;    // *** Chiến thuật M5, M15: ema10 cắt ema20 theo trend ema200
input ENUM_TIMEFRAMES InpEma10Ema20Ema200AlgoTF = PERIOD_M5;    // |- Khung thời gian
#include  "..\libs\Algorithm\Ema10Ema20Ema200.mqh"

input bool InpAutoTrade_UseEma200MacdAlgo = false;    // *** Chiến thuật M5, M15: macd cắt 0 theo trend EMA200
input ENUM_TIMEFRAMES InpEma200MacdAlgoTF = PERIOD_M15;    // |- Khung thời gian
#include  "..\libs\Algorithm\Ema200Macd.mqh"

// ===================================================================
// Tham số đầu vào của EA [ end ]
// ===================================================================


// ===================================================================
// Khai báo các đối tượng cục bộ [start]
// ===================================================================
// Sử dụng đối tượng để thao tác mở lệnh trong EA
CTrade        m_trader;
// Đối tượng truy xuất thông tin giá
AllSeriesInfo m_infoCurrency, m_infoCurrencyRandomAlgo, 
              m_infoCurrencyAdxBBEma200Algo, m_infoCurrencyEma10Ema20Ema200Algo,
              m_infoCurrencyEma200MacdAlgo;

// Thông tin chung
string m_symbolCurrency;    // Cặp tiền tệ đang trade
ENUM_TIMEFRAMES m_tf;       // Khung thời gian đang trade
int m_prevCalculated;       // Lưu số lượng nến trước đó, dùng để tính số lượng nến phát sinh
int m_limit;                // Lưu số lượng nến phát sinh động

CHedge *m_hedge;
CRandom *m_randomAlgo;
CAdxBBEma200 *m_adxBBEma200Algo;
CEma10Ema20Ema200 *m_ema10Ema20Ema200Algo;
CEma200Macd *m_ema200MacdAlgo;

CGuiTrade *m_guiTrade;

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
    
    string lots[];
    
    // Khởi tạo đối tượng hedge
    if(InpUseHedge)
    {
        m_hedge = new CHedge();
        m_hedge.InitHedge(m_symbolCurrency, PERIOD_CURRENT, m_trader, m_infoCurrency, MAGIC_NUMBER);
        m_hedge.MaxWireHedge(InpHedgeMaxWire);
        m_hedge.RR(InpHedgeRiskReward);
        m_hedge.LotChain(InpHedgeLotsChain);
        m_hedge.ExpectProfit(InpHedgeExpectProfit);
        m_hedge.SetAppendComment(InpCommentPlus);
        
        Split(InpHedgeLotsChain, ";", lots);
    }
    
    
        
    // Khởi tạo các đối tượng trade tự động
    if(InpAutoTrade)
    {
        if(InpAutoTrade_UseRandomAlgo)
        {
            m_infoCurrencyRandomAlgo.init(m_symbolCurrency, InpRandomAlgoTF);
            m_randomAlgo = new CRandom();
            m_randomAlgo.Init(m_symbolCurrency, InpRandomAlgoTF, m_trader, m_infoCurrencyRandomAlgo, InpCommentPlus, MAGIC_NUMBER);
            if(InpUseHedge && ArraySize(lots) > 0)
                m_randomAlgo.Vol(lots[0]);
        }
        
        if(InpAutoTrade_UseAdxBBEm200Algo)
        {
            m_infoCurrencyAdxBBEma200Algo.init(m_symbolCurrency, InpAdxBBEm200AlgoTF);
            m_adxBBEma200Algo = new CAdxBBEma200();
            m_adxBBEma200Algo.Init(m_symbolCurrency, InpAdxBBEm200AlgoTF, m_trader, m_infoCurrencyAdxBBEma200Algo, InpCommentPlus, MAGIC_NUMBER);
            if(InpUseHedge && ArraySize(lots) > 0)
                m_adxBBEma200Algo.Vol(lots[0]);
        }
        
        if(InpAutoTrade_UseEma10Ema20Ema200Algo)
        {
            m_infoCurrencyEma10Ema20Ema200Algo.init(m_symbolCurrency, InpEma10Ema20Ema200AlgoTF);
            m_ema10Ema20Ema200Algo = new CEma10Ema20Ema200();
            m_ema10Ema20Ema200Algo.Init(m_symbolCurrency, InpEma10Ema20Ema200AlgoTF, m_trader, m_infoCurrencyEma10Ema20Ema200Algo, InpCommentPlus, MAGIC_NUMBER);
            if(InpUseHedge && ArraySize(lots) > 0)
                m_ema10Ema20Ema200Algo.Vol(lots[0]);
        }
        
        if(InpAutoTrade_UseEma200MacdAlgo)
        {
            m_infoCurrencyEma200MacdAlgo.init(m_symbolCurrency, InpEma200MacdAlgoTF);
            m_ema200MacdAlgo = new CEma200Macd();
            m_ema200MacdAlgo.Init(m_symbolCurrency, InpEma200MacdAlgoTF, m_trader, m_infoCurrencyEma200MacdAlgo, InpCommentPlus, MAGIC_NUMBER);
            if(InpUseHedge && ArraySize(lots) > 0)
                m_ema200MacdAlgo.Vol(lots[0]);
        }
    }
    
    // Khởi tạo công cụ thiết lập SL, TP, Entry trên giao diện
    m_guiTrade = new CGuiTrade();
    TAction actSell = OnSellCustom;
    TAction actBuy = OnBuyCustom;
    m_guiTrade.OnSell(actSell);
    m_guiTrade.OnBuy(actBuy);
    m_guiTrade.Init(m_symbolCurrency, m_tf, m_trader, m_infoCurrency);
    if(InpUseHedge && ArraySize(lots) > 0)
            m_guiTrade.Risk(lots[0]);
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
    
    // ===================================================================
    // Xử lý chính giao dịch [start]
    // ===================================================================
    
    // Gọi xử lý của đối tượng hedge
    if(InpUseHedge)
        m_hedge.Process(m_limit);
    
    // 
    if(InpAutoTrade)
    {
        if(InpAutoTrade_UseRandomAlgo)
        {
            m_randomAlgo.Process(m_limit);
        }
        if(InpAutoTrade_UseAdxBBEm200Algo)
        {
            m_adxBBEma200Algo.Process(m_limit);
        }
        if(InpAutoTrade_UseEma10Ema20Ema200Algo)
        {
            m_ema10Ema20Ema200Algo.Process(m_limit);
        }
        if(InpAutoTrade_UseEma200MacdAlgo)
        {
            m_ema200MacdAlgo.Process(m_limit);
        }
    }
    
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

//+------------------------------------------------------------------+
//| Sự kiện chính
//+------------------------------------------------------------------+
void OnTick()
{
    Process();
}

//+------------------------------------------------------------------+
// Sự kiện nút SELL trên bảng điều khiển
//+------------------------------------------------------------------+
void OnSellCustom()
{
    m_infoCurrency.refresh();
    
    double entry, sl, tp;
    string comment = "";
    if(m_guiTrade.ExistEntryLine() && m_guiTrade.ExistSLLine() && m_guiTrade.ExistTPLine())
    {
        entry = m_guiTrade.Entry();
        sl = m_guiTrade.SL();
        tp = m_guiTrade.TP();
    }
    else
    {
        return;
    }
    
    if(sl <= entry || tp >= entry)
        return;

    int slPoint = PriceShiftToPoints(m_symbolCurrency, MathAbs(entry - sl));
    double lot = PointsToLots(m_symbolCurrency, m_guiTrade.Risk(), slPoint);
    if(!m_guiTrade.UseRiskOnGUI())
        lot = m_guiTrade.Risk();
        
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
    
    if(InpUseHedge)
    {
        comment = InpCommentPlus;
        int slPoints = PriceShiftToPoints(m_symbolCurrency, MathAbs(entry - sl));
        int tpPoints = PriceShiftToPoints(m_symbolCurrency, MathAbs(entry - tp));
        comment += ";01;" + slPoints + ";" + tpPoints;
    }
    
    if(entry > m_infoCurrency.bid())
    {
        m_trader.SellLimit(lot, entry, m_symbolCurrency, sl, tp, 0, 0, comment);
    }
    else if(entry < m_infoCurrency.bid())
    {
        m_trader.SellStop(lot, entry, m_symbolCurrency, sl, tp, 0, 0, comment);
    }
        
}

//+------------------------------------------------------------------+
// Sự kiện nút BUY trên bảng điều khiển
//+------------------------------------------------------------------+
void OnBuyCustom()
{
    m_infoCurrency.refresh();
    
    double entry, sl, tp;
    string comment = "";
    
    if(m_guiTrade.ExistEntryLine() && m_guiTrade.ExistSLLine() && m_guiTrade.ExistTPLine())
    {
        entry = m_guiTrade.Entry();
        sl = m_guiTrade.SL();
        tp = m_guiTrade.TP();
    }
    else
    {
        return;
    }
    
    if(sl >= entry || tp <= entry)
        return;

    int slPoint = PriceShiftToPoints(m_symbolCurrency, MathAbs(entry - sl));
    double lot = PointsToLots(m_symbolCurrency, m_guiTrade.Risk(), slPoint);
    if(!m_guiTrade.UseRiskOnGUI())
        lot = m_guiTrade.Risk();
        
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
    
    if(InpUseHedge)
    {
        comment = InpCommentPlus;
        int slPoints = PriceShiftToPoints(m_symbolCurrency, MathAbs(entry - sl));
        int tpPoints = PriceShiftToPoints(m_symbolCurrency, MathAbs(entry - tp));
        comment += ";01;" + slPoints + ";" + tpPoints;
    }
    
    if(entry < m_infoCurrency.ask())
    {
        m_trader.BuyLimit(lot, entry, m_symbolCurrency, sl, tp, 0, 0, comment);
    }
    else if(entry > m_infoCurrency.ask())
    {
        m_trader.BuyStop(lot, entry, m_symbolCurrency, sl, tp, 0, 0, comment);
    }
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
    m_guiTrade.ProcessChartEvent(id,lparam,dparam,sparam);
}