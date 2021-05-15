#include <Trade\PositionInfo.mqh>
#include  "..\ExpertWrapper.mqh"
#include  "..\Common.mqh"
#include  "..\CLineH.mqh"
#include  "..\BuySellDialog.mqh"

const string CONST_ENTRY_ID = "entry001";
const string CONST_ENTRY_TEXT = "Entry";
const string CONST_SL_ID = "sl001";
const string CONST_SL_TEXT = "SL";
const string CONST_TP_ID = "tp001";
const string CONST_TP_TEXT = "TP";



class CGuiTrade
{
    private:
        string m_symbolCurrency;
        CTrade m_trader;
        AllSeriesInfo m_infoCurrency;
        ENUM_TIMEFRAMES m_tf;
        
        CLineH *m_lineEntry, *m_lineSL, *m_lineTP;
        CControlsDialog *ExtDialog;
        
        TAction m_actionSell, m_actionBuy;
    public:
        bool ExistEntryLine()
        {
            return m_lineEntry.ExistObject();
        }
        double Entry()
        {
            if(ExistEntryLine())
                return m_lineEntry.Price();
            return 0;
        }
        bool ExistSLLine()
        {   
            return m_lineSL.ExistObject();
        }
        double SL()
        {
            if(ExistSLLine())
                return m_lineSL.Price();
            return 0;
        }
        bool ExistTPLine()
        {
            return m_lineTP.ExistObject();
        }
        double TP()
        {
            if(ExistTPLine())
                return m_lineTP.Price();
            return 0;
        }
        void OnSell(TAction act)
        {
            m_actionSell = act;
        }
        void OnBuy(TAction act)
        {
            m_actionBuy = act;
        }
        double Risk()
        {
            return ExtDialog.Risk();
        }
        void Risk(double r)
        {
            ExtDialog.Risk(r);
        }
        bool UseRiskOnGUI()
        {
            return ExtDialog.UseRiskOnGUI();
        }
        
        bool Init(string symbol, ENUM_TIMEFRAMES tf, 
                  CTrade &trader, AllSeriesInfo &infoCurrency)
        {
            m_symbolCurrency = symbol;
            m_tf = tf;
            m_trader = trader;
            m_infoCurrency = infoCurrency;
            
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
                return(false);
            ExtDialog.SetActionButtonSell(m_actionSell);
            ExtDialog.SetActionButtonBuy(m_actionBuy);
            ExtDialog.Run();
            // ===================================================================
            return true;
        }
        void Process(int limit)
        {
        
        }
        void ReleaseObject(const int reason)
        {
            // Hủy đối tượng: bảng điều khiển
            if(ExtDialog != NULL)
                ExtDialog.Destroy(reason);
        }
        void ProcessChartEvent(const int id,       // event id
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
    protected:
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
            if(!ExtDialog.UseRiskOnGUI())
                lot = ExtDialog.Risk();
                
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
    
};