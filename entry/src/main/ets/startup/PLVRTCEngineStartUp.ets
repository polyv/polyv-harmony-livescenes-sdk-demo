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
    // PLVRTCEngineFactory.register(PLVTRTCEngineFactory.instance) TODO 如需集成trtc，请联系技术支持
    // PLVRTCEngineFactory.register(PLVVRTCEngineFactory.instance) TODO 如需集成vrtc，请联系技术支持
  }
}