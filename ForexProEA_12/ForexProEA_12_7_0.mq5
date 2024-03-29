#property description "Quản lý vốn theo phương pháp Hedge"
#property copyright "ForexProEA"
#property link "https://www.facebook.com/groups/forexproea/"
#property version   "12.70"

// Mã số định danh cho EA (để phân biệt với các EA khác)
#define MAGIC_NUMBER 10001270

#include <trade/trade.mqh>
#include <expert/expertbase.mqh>
#include  "..\libs\ExpertWrapper.mqh"
#include  "..\libs\Common.mqh"
#include  "..\libs\Hedge.mqh"

// ===================================================================
// Tham số đầu vào của EA [start]
// ===================================================================
input string InpCommentPlus = "hedge";  // Ghi chú thêm vào mỗi lệnh

input group "Trade tự động"
input bool InpAutoTrade = true;     // Dùng chức năng trade tự động
input bool InpAutoTrade_UseRandomAlgorithm = true;  // Mở lệnh ngẫu nhiên
#include  "..\libs\Algorithm\Random.mqh"

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

CHedge *m_hedge;
CRandom *m_randomAlgo;

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
        
    // Khởi tạo đối tượng hedge
    if(InpUseHedge)
    {
        m_hedge = new CHedge();
        m_hedge.InitHedge(m_symbolCurrency, PERIOD_CURRENT, m_trader, m_infoCurrency, MAGIC_NUMBER);
        m_hedge.MaxWireHedge(InpHedgeMaxWire);
        m_hedge.RR(InpHedgeRiskReward);
        m_hedge.SetAppendComment(InpCommentPlus);
    }
    if(InpAutoTrade)
    {
        if(InpAutoTrade_UseRandomAlgorithm)
        {
            m_randomAlgo = new CRandom();
            m_randomAlgo.Init(m_symbolCurrency, m_tf, m_trader, m_infoCurrency, InpCommentPlus, MAGIC_NUMBER);
            string lots[];
            Split(InpLotsChain, ";", lots);
            if(ArraySize(lots) > 0)
                m_randomAlgo.Vol(lots[0]);
        }
    }
    
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
        if(InpAutoTrade_UseRandomAlgorithm)
        {
            m_randomAlgo.Process(m_limit);
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
