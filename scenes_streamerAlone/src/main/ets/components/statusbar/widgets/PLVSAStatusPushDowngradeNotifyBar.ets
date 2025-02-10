import {
  PLVLiveSceneSDK,
  PLVNetworkStatistics,
  PLVPushDowngradePreference,
  PLVToastUtils
} from "@polyvharmony/live-scenes-sdk";
import { lateInit, minutes, MutableObserver, seconds } from "@polyvharmony/media-player-sdk";

@Component
export struct PLVSAStatusPushDowngradeNotifyBar {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @State private isVisible: boolean = false
  private lastShowNotifyTimestamp = 0
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    this.sdk.linkmicManager.linkmicNetworkStatistics.observe(it => this.onNetworkStatistics(it))
      .pushTo(this.observers)
  }

  build() {
    if (this.isVisible) {
      Row() {
        Text($r('app.string.plvsa_push_downgrade_notify_text'))
          .fontColor('#F0F1F5')
          .fontSize(12)
          .margin({
            left: 12
          })
        Text($r('app.string.plvsa_push_downgrade_notify_action'))
          .fontColor('#FF6363')
          .fontSize(12)
          .padding(4)
          .onClick(() => {
            this.sdk.streamerManager.setPushDowngradePreference(PLVPushDowngradePreference.PREFER_BETTER_FLUENCY)
            PLVToastUtils.shortShow($r('app.string.plvsa_push_downgrade_notify_switch_success'))
            this.hide()
          })
        Image($r("app.media.plvsa_status_bar_push_downgrade_notify_bar_close_icon"))
          .width(24)
          .height(24)
          .padding(6)
          .margin({
            left: 4,
            right: 4
          })
          .onClick(() => this.hide())
      }
      .backgroundColor('#991B202D')
      .borderRadius(40)
    }
  }

  private onNetworkStatistics(networkStatistics: PLVNetworkStatistics) {
    const isBadNetwork = networkStatistics.upLossRate > 30
    const canChangeToFluency = this.sdk.streamerManager.pushDowngradePreference.value === PLVPushDowngradePreference.PREFER_BETTER_QUALITY
    if (isBadNetwork && canChangeToFluency && Date.now() - this.lastShowNotifyTimestamp > minutes(10).toMillis()) {
      this.show()
    }
  }

  private show() {
    this.lastShowNotifyTimestamp = Date.now()
    this.isVisible = true
    setTimeout(() => {
      this.hide()
    }, seconds(10).toMillis())
  }

  private hide() {
    this.isVisible = false
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
    this.observers = []
  }
}