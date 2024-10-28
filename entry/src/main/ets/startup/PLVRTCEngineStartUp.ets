import { PLVARTCEngineFactory } from "@polyvharmony/rtc-core-artc";
import { PLVRTCEngineFactory } from "@polyvharmony/rtc-sdk";

export class PLVRTCEngineStartUp {
  private static isInit = false;

  static start() {
    if (PLVRTCEngineStartUp.isInit) {
      return
    }
    PLVRTCEngineStartUp.isInit = true

    PLVRTCEngineFactory.register(PLVARTCEngineFactory.instance)
  }
}