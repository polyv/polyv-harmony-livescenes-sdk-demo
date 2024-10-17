import { PLVBaseModule, PLVPreferencesUtils } from '@polyvharmony/live-scenes-sdk'

const PREFERENCE_NAME = "plv_card_look_time_local_cache"

export class PLVCardLookTimeLocalRepository {
  // <editor-fold defaultstate="collapsed" desc="对外API">
  static saveCache(channelId: string, id: string, lookTime: number) {
    PLVPreferencesUtils.put(`${channelId}_${id}`, lookTime, PREFERENCE_NAME)
  }

  static getCache(channelId: string, id: string): Promise<number> {
    return PLVPreferencesUtils.getNumber(`${channelId}_${id}`, PREFERENCE_NAME)
  }

  static hasSaveCache(channelId: string, id: string) {
    PLVPreferencesUtils.has(`${channelId}_${id}`, PREFERENCE_NAME)
  }
  // </editor-fold>

}