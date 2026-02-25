import { useEffect, useRef } from 'react';

const isDebug = typeof (window as any).GetParentResourceName !== 'function';

if (isDebug) {
  document.body.style.background = 'rgba(0, 0, 0, 0.6)';
}

export { isDebug };

export function debugNuiEvent(action: string, data: unknown) {
  window.postMessage({ action, data }, '*');
}

export function useNuiEvent<T = unknown>(action: string, handler: (data: T) => void) {
  const savedHandler = useRef(handler);
  useEffect(() => { savedHandler.current = handler; }, [handler]);
  useEffect(() => {
    function eventListener(event: any) {
      const { action: eventAction, data } = event.data ?? {};
      if (eventAction === action) savedHandler.current((data ?? {}) as T);
    }
    window.addEventListener('message', eventListener);
    return () => window.removeEventListener('message', eventListener);
  }, [action]);
}

export async function fetchNui<T = unknown>(
  eventName: string,
  data: Record<string, unknown> = {},
  mockData?: T
): Promise<T> {
  if (isDebug && mockData !== undefined) {
    console.log(`[NUI Dev] ${eventName}:`, mockData);
    return mockData;
  }
  if (isDebug) {
    console.warn(`[NUI Dev] No mock for '${eventName}'. Pass mockData as 3rd arg.`);
    return {} as T;
  }
  const resourceName = (window as any).GetParentResourceName();
  const response = await fetch(`https://${resourceName}/${eventName}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data),
  });
  return response.json();
}

if (isDebug) {
  setTimeout(() => debugNuiEvent('open', {
    balance: 50,
    totalTraded: 1250,
    rewards: [
      { item: 'plastic', label: 'Plastic', rarity: 'common', baseChance: 45, minAmount: 1, maxAmount: 3 },
      { item: 'metalscrap', label: 'Metal Scrap', rarity: 'common', baseChance: 40, minAmount: 1, maxAmount: 3 },
      { item: 'glass', label: 'Glass', rarity: 'common', baseChance: 35, minAmount: 1, maxAmount: 2 },
      { item: 'copper', label: 'Copper', rarity: 'uncommon', baseChance: 25, minAmount: 1, maxAmount: 2 },
      { item: 'steel', label: 'Steel', rarity: 'uncommon', baseChance: 20, minAmount: 1, maxAmount: 2 },
      { item: 'aluminum', label: 'Aluminum', rarity: 'uncommon', baseChance: 18, minAmount: 1, maxAmount: 2 },
      { item: 'electronics', label: 'Electronics', rarity: 'rare', baseChance: 12, minAmount: 1, maxAmount: 1 },
      { item: 'rubber', label: 'Rubber', rarity: 'rare', baseChance: 10, minAmount: 1, maxAmount: 2 },
      { item: 'goldbar', label: 'Gold Bar', rarity: 'epic', baseChance: 5, minAmount: 1, maxAmount: 1 },
      { item: 'diamond', label: 'Diamond', rarity: 'epic', baseChance: 3, minAmount: 1, maxAmount: 1 },
    ],
    scaling: [
      { minAmount: 1, maxAmount: 10, itemMin: 1, itemMax: 3 },
      { minAmount: 11, maxAmount: 25, itemMin: 5, itemMax: 10 },
      { minAmount: 26, maxAmount: 50, itemMin: 11, itemMax: 25 },
      { minAmount: 51, maxAmount: 100, itemMin: 26, itemMax: 50 },
      { minAmount: 101, maxAmount: 999999, itemMin: 50, itemMax: 100 }
    ],
    sellableItems: [
      { name: 'plastic', label: 'Plastic', amount: 12, price: 15 },
      { name: 'metalscrap', label: 'Metal Scrap', amount: 8, price: 18 },
      { name: 'copper', label: 'Copper', amount: 5, price: 35 },
      { name: 'electronics', label: 'Electronics', amount: 2, price: 75 },
      { name: 'goldbar', label: 'Gold Bar', amount: 1, price: 250 },
    ]
  }), 100);
}
