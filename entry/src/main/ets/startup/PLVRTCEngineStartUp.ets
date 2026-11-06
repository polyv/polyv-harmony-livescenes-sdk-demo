import { PLVARTCEngineFactory } from '@polyvharmony/rtc-core-artc';
import { PLVTRTCEngineFactory } from '@polyvharmony/rtc-core-trtc';
import { PLVVRTCEngineFactory } from '@polyvharmony/rtc-core-vrtc';
import { PLVRTCEngineFactory } from '@polyvharmony/rtc-sdk';

export class PLVRTCEngineStartUp {
  private static isInit = false;

  static start() {
    if (PLVRTCEngineStartUp.isInit) {
      return
    }
    PLVRTCEngineStartUp.isInit = true

    PLVRTCEngineFactory.register(PLVARTCEngineFactory.instance)
    PLVRTCEngineFactory.register(PLVTRTCEngineFactory.instance)
    // PLVRTCEngineFactory.register(PLVVRTCEngineFactory.instance)
  }
}