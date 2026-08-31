import { PLVLWPiPEntranceBridge } from './src/main/ets/common/PLVLWPiPEntranceBridge'

// pages
export { pushToLiveWatchPage } from './src/main/ets/pages/PLVLWWatchPage'

// pip
export async function closeLiveWatchPiPForNewSession(): Promise<void> {
  await PLVLWPiPEntranceBridge.instance.closeForNewSession()
}

// sdk
export * from '@polyvharmony/live-scenes-sdk'
