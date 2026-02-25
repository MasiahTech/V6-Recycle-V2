import { useState, useCallback, useEffect } from 'react';
import { isDebug, useNuiEvent, fetchNui } from './hooks/useNui';

interface Reward {
  item: string;
  label: string;
  rarity: 'common' | 'uncommon' | 'rare' | 'epic';
  baseChance: number;
  minAmount: number;
  maxAmount: number;
}

interface ScalingBonus {
  minAmount: number;
  maxAmount: number;
  itemMin: number;
  itemMax: number;
}

interface SellableItem {
  name: string;
  label: string;
  amount: number;
  price: number;
}

interface TradingData {
  balance: number;
  totalTraded: number;
  rewards: Reward[];
  scaling: ScalingBonus[];
  sellableItems: SellableItem[];
}

interface TradeResult {
  rewards: Array<{
    item: string;
    label: string;
    amount: number;
    rarity: string;
  }>;
  totalTraded: number;
  newBalance: number;
}

const rarityColors = {
  common: {
    border: 'border-gray-500/40',
    text: 'text-gray-400',
    accent: 'bg-gray-500/10'
  },
  uncommon: {
    border: 'border-emerald-500/40',
    text: 'text-emerald-400',
    accent: 'bg-emerald-500/10'
  },
  rare: {
    border: 'border-blue-500/40',
    text: 'text-blue-400',
    accent: 'bg-blue-500/10'
  },
  epic: {
    border: 'border-purple-500/40',
    text: 'text-purple-400',
    accent: 'bg-purple-500/10'
  },
};

export default function App() {
  const [visible, setVisible] = useState(isDebug);
  const [tradingData, setTradingData] = useState<TradingData | null>(null);
  const [tradeAmount, setTradeAmount] = useState(1);
  const [showResults, setShowResults] = useState(false);
  const [tradeResults, setTradeResults] = useState<TradeResult | null>(null);
  const [activeTab, setActiveTab] = useState<'trade' | 'sell'>('trade');
  const [sellAmounts, setSellAmounts] = useState<Record<string, number>>({});

  useNuiEvent<TradingData>('open', (data) => {
    setVisible(true);
    setTradingData(data);
    setTradeAmount(Math.min(1, data.balance));
    setShowResults(false);
    setActiveTab('trade');
  });

  useNuiEvent('close', () => setVisible(false));

  useNuiEvent<TradeResult>('tradeComplete', (data) => {
    setTradeResults(data);
    setShowResults(true);
    if (tradingData) {
      setTradingData({
        ...tradingData,
        balance: data.newBalance,
        totalTraded: data.totalTraded,
      });
    }
    setTradeAmount(Math.min(1, data.newBalance));
  });

  const handleClose = useCallback(() => {
    setVisible(false);
    setShowResults(false);
    fetchNui('close', {}, { success: true });
  }, []);

  useEffect(() => {
    const onKeyDown = (e: any) => {
      if (e.key === 'Escape') handleClose();
    };
    window.addEventListener('keydown', onKeyDown);
    return () => window.removeEventListener('keydown', onKeyDown);
  }, [handleClose]);

  const getCurrentRange = () => {
    if (!tradingData) return { min: 1, max: 3 };
    const bonus = tradingData.scaling.find(
      (s) => tradeAmount >= s.minAmount && tradeAmount <= s.maxAmount
    );
    return { min: bonus?.itemMin || 1, max: bonus?.itemMax || 3 };
  };

  const handleTrade = () => {
    if (!tradingData || tradeAmount < 1 || tradeAmount > tradingData.balance) return;
    fetchNui('tradeMaterials', { amount: tradeAmount });
  };

  const handleSell = (itemName: string, amount: number) => {
    fetchNui('sellResource', { itemName, amount });
    
    if (tradingData) {
      const updatedItems = tradingData.sellableItems.map(item => {
        if (item.name === itemName) {
          return { ...item, amount: Math.max(0, item.amount - amount) };
        }
        return item;
      }).filter(item => item.amount > 0);
      
      setTradingData({ ...tradingData, sellableItems: updatedItems });
      setSellAmounts({ ...sellAmounts, [itemName]: 1 });
    }
  };

  const setSellAmount = (itemName: string, amount: number) => {
    setSellAmounts({ ...sellAmounts, [itemName]: amount });
  };

  if (!visible || !tradingData) return null;

  const currentRange = getCurrentRange();
  const isBonus = currentRange.min > 1 || currentRange.max > 3;

  return (
    <div className="fixed inset-0 flex items-center justify-center bg-black/10">
      <div className="w-[800px] max-w-[90vw] max-h-[90vh] bg-black/30 backdrop-blur-sm border border-white/10 rounded-none shadow-2xl overflow-hidden">
        <div className="bg-white/[0.02] border-b border-white/10 px-6 py-4">
          <div className="flex items-center justify-between mb-3">
            <div>
              <h1 className="text-xl font-semibold text-white tracking-wide uppercase">Recycle Center</h1>
              <p className="text-gray-400 text-xs mt-1">Trade materials and sell resources</p>
            </div>
            <button
              onClick={handleClose}
              className="w-8 h-8 flex items-center justify-center rounded hover:bg-white/10 text-gray-400 hover:text-white transition-all"
            >
              ✕
            </button>
          </div>
          
          <div className="flex gap-1">
            <button
              onClick={() => { setActiveTab('trade'); setShowResults(false); }}
              className={`flex-1 px-4 py-2 font-medium text-sm transition-all ${
                activeTab === 'trade'
                  ? 'bg-white/10 text-white border-b-2 border-white'
                  : 'bg-transparent text-gray-400 hover:text-white hover:bg-white/5'
              }`}
            >
              Trade Materials
            </button>
            <button
              onClick={() => setActiveTab('sell')}
              className={`flex-1 px-4 py-2 font-medium text-sm transition-all ${
                activeTab === 'sell'
                  ? 'bg-white/10 text-white border-b-2 border-white'
                  : 'bg-transparent text-gray-400 hover:text-white hover:bg-white/5'
              }`}
            >
              Sell Resources
            </button>
          </div>
        </div>

        <div className="p-6 space-y-4 overflow-y-auto max-h-[calc(90vh-160px)]">
          {activeTab === 'trade' ? (
            <>
              <div className="grid grid-cols-2 gap-3">
                <div className="bg-white/[0.02] border border-white/10 p-4">
                  <div className="text-gray-400 text-xs uppercase tracking-widest mb-2">Current Balance</div>
                  <div className="text-3xl font-bold text-white">{tradingData.balance}</div>
                  <div className="text-gray-500 text-xs mt-1">Recyclable Materials</div>
                </div>
                <div className="bg-white/[0.02] border border-white/10 p-4">
                  <div className="text-gray-400 text-xs uppercase tracking-widest mb-2">Lifetime Traded</div>
                  <div className="text-3xl font-bold text-white">{tradingData.totalTraded}</div>
                  <div className="text-gray-500 text-xs mt-1">Total Materials</div>
                </div>
              </div>

              {!showResults ? (
                <>
                  <div className="bg-white/[0.02] border border-white/10 p-5">
                    <div className="flex items-center justify-between mb-4">
                      <label className="text-white font-medium text-sm uppercase tracking-wider">Trade Amount</label>
                      {isBonus && (
                        <span className="text-xs px-2 py-1 bg-emerald-500/20 text-emerald-400 border border-emerald-500/40 font-medium">
                          {currentRange.min}-{currentRange.max} ITEMS
                        </span>
                      )}
                    </div>
                    
                    <input
                      type="range"
                      min="1"
                      max={tradingData.balance}
                      value={tradeAmount}
                      onChange={(e) => setTradeAmount(Number(e.target.value))}
                      className="w-full h-1 bg-white/10 appearance-none cursor-pointer accent-white"
                      style={{
                        background: `linear-gradient(to right, rgb(255 255 255) 0%, rgb(255 255 255) ${(tradeAmount / tradingData.balance) * 100}%, rgba(255,255,255,0.1) ${(tradeAmount / tradingData.balance) * 100}%, rgba(255,255,255,0.1) 100%)`
                      }}
                    />
                    
                    <div className="flex items-center justify-between mt-3">
                      <input
                        type="number"
                        min="1"
                        max={tradingData.balance}
                        value={tradeAmount}
                        onChange={(e) => setTradeAmount(Math.min(Math.max(1, Number(e.target.value)), tradingData.balance))}
                        className="w-24 bg-black/30 border border-white/20 px-3 py-2 text-white text-center focus:outline-none focus:border-white/40"
                      />
                      <div className="flex gap-2">
                        <button
                          onClick={() => setTradeAmount(Math.ceil(tradingData.balance * 0.25))}
                          className="px-3 py-1.5 text-xs bg-white/[0.02] hover:bg-white/5 text-gray-300 border border-white/10 transition-colors"
                        >
                          25%
                        </button>
                        <button
                          onClick={() => setTradeAmount(Math.ceil(tradingData.balance * 0.5))}
                          className="px-3 py-1.5 text-xs bg-white/[0.02] hover:bg-white/5 text-gray-300 border border-white/10 transition-colors"
                        >
                          50%
                        </button>
                        <button
                          onClick={() => setTradeAmount(tradingData.balance)}
                          className="px-3 py-1.5 text-xs bg-white/[0.02] hover:bg-white/5 text-gray-300 border border-white/10 transition-colors"
                        >
                          MAX
                        </button>
                      </div>
                    </div>
                  </div>

                  <div>
                    <div className="mb-3">
                      <h2 className="text-white font-medium text-sm uppercase tracking-wider">Possible Rewards</h2>
                      <p className="text-xs text-gray-500 mt-1">Each reward gives {currentRange.min}-{currentRange.max} items</p>
                    </div>
                    <div className="grid grid-cols-2 gap-2 max-h-[200px] overflow-y-auto pr-2">
                      {tradingData.rewards.map((reward, idx) => {
                        const colors = rarityColors[reward.rarity];
                        return (
                          <div
                            key={idx}
                            className={`bg-white/[0.02] border ${colors.border} ${colors.accent} p-3 hover:bg-white/5 transition-all`}
                          >
                            <div className={`font-medium text-sm ${colors.text}`}>{reward.label}</div>
                            <div className="text-xs text-gray-400 mt-1">
                              {reward.baseChance}% • {currentRange.min}-{currentRange.max}x
                              {isBonus && <span className="text-emerald-400 ml-1">↑</span>}
                            </div>
                          </div>
                        );
                      })}
                    </div>
                  </div>

                  <button
                    onClick={handleTrade}
                    disabled={tradeAmount < 1 || tradeAmount > tradingData.balance}
                    className="w-full py-3 bg-white text-black hover:bg-gray-200 disabled:bg-white/10 disabled:text-gray-600 disabled:cursor-not-allowed font-semibold uppercase tracking-wider transition-all text-sm"
                  >
                    Trade {tradeAmount} Material{tradeAmount !== 1 ? 's' : ''}
                  </button>
                </>
              ) : (
                <>
                  <div className="bg-white/[0.02] border border-white/10 p-5">
                    <h2 className="text-lg font-semibold text-white mb-4 text-center uppercase tracking-wider">Trade Complete</h2>
                    
                    {tradeResults && tradeResults.rewards.length > 0 ? (
                      <div className="space-y-2">
                        {tradeResults.rewards.map((reward, idx) => {
                          const colors = rarityColors[reward.rarity as keyof typeof rarityColors];
                          return (
                            <div
                              key={idx}
                              className={`bg-white/5 border ${colors.border} ${colors.accent} p-3 flex items-center justify-between`}
                              style={{ animationDelay: `${idx * 0.1}s` }}
                            >
                              <span className={`font-medium ${colors.text}`}>{reward.label}</span>
                              <span className={`font-bold ${colors.text}`}>+{reward.amount}x</span>
                            </div>
                          );
                        })}
                      </div>
                    ) : (
                      <div className="text-center text-gray-400 py-4">
                        No items found this time. Better luck next trade!
                      </div>
                    )}
                  </div>

                  <button
                    onClick={() => setShowResults(false)}
                    className="w-full py-3 bg-white/[0.02] hover:bg-white/10 text-white font-semibold border border-white/20 uppercase tracking-wider transition-all text-sm"
                  >
                    Trade Again
                  </button>
                </>
              )}
            </>
          ) : (
            <div className="space-y-3">
              <div className="bg-white/5 border border-white/10 p-4">
                <h3 className="text-white font-medium text-sm uppercase tracking-wider mb-1">Sell Your Resources</h3>
                <p className="text-gray-400 text-xs">Convert items from trading into cash</p>
              </div>

              {tradingData.sellableItems && tradingData.sellableItems.length > 0 ? (
                <div className="space-y-2">
                  {tradingData.sellableItems.map((item) => {
                    const currentAmount = sellAmounts[item.name] || 1;
                    const maxAmount = item.amount;
                    const totalValue = item.price * currentAmount;

                    return (
                      <div
                        key={item.name}
                        className="bg-white/[0.02] border border-white/10 p-4 hover:bg-white/5 transition-all"
                      >
                        <div className="flex items-center justify-between mb-3">
                          <div>
                            <h4 className="text-white font-medium text-sm">{item.label}</h4>
                            <p className="text-gray-400 text-xs mt-1">
                              ${item.price} each • You have: {item.amount}
                            </p>
                          </div>
                          <div className="text-right">
                            <div className="text-emerald-400 font-bold text-lg">${totalValue}</div>
                            <div className="text-gray-500 text-xs">Total Value</div>
                          </div>
                        </div>

                        <div className="flex items-center gap-3">
                          <input
                            type="range"
                            min="1"
                            max={maxAmount}
                            value={currentAmount}
                            onChange={(e) => setSellAmount(item.name, Number(e.target.value))}
                            className="flex-1 h-1 bg-white/10 appearance-none cursor-pointer accent-emerald-500"
                            style={{
                              background: `linear-gradient(to right, rgb(16 185 129) 0%, rgb(16 185 129) ${(currentAmount / maxAmount) * 100}%, rgba(255,255,255,0.1) ${(currentAmount / maxAmount) * 100}%, rgba(255,255,255,0.1) 100%)`
                            }}
                          />
                          <input
                            type="number"
                            min="1"
                            max={maxAmount}
                            value={currentAmount}
                            onChange={(e) => setSellAmount(item.name, Math.min(Math.max(1, Number(e.target.value)), maxAmount))}
                            className="w-16 bg-black/30 border border-white/20 px-2 py-1.5 text-white text-center text-sm focus:outline-none focus:border-white/40"
                          />
                          <button
                            onClick={() => handleSell(item.name, currentAmount)}
                            className="px-4 py-2 bg-emerald-500 hover:bg-emerald-400 text-black font-medium uppercase text-xs tracking-wider transition-all"
                          >
                            Sell
                          </button>
                        </div>

                        <div className="flex gap-2 mt-2">
                          <button
                            onClick={() => handleSell(item.name, maxAmount)}
                            className="flex-1 px-3 py-1.5 text-xs bg-white/5 hover:bg-white/10 text-gray-300 border border-white/10 transition-colors uppercase tracking-wider"
                          >
                            Sell All ({maxAmount}x)
                          </button>
                        </div>
                      </div>
                    );
                  })}
                </div>
              ) : (
                <div className="bg-white/5 border border-white/10 p-8 text-center">
                  <div className="text-gray-400 text-sm mb-2 uppercase tracking-wider">No Resources Available</div>
                  <p className="text-gray-500 text-xs">Trade materials first to get resources you can sell</p>
                </div>
              )}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
