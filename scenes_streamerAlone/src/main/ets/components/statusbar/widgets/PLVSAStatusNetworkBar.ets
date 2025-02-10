import { PLVLiveSceneSDK, PLVNetworkQuality, PLVNetworkStatistics } from '@polyvharmony/live-scenes-sdk'
import { lateInit, MutableObserver } from '@polyvharmony/media-player-sdk'

@Component
export struct PLVSAStatusNetworkBar {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @State private networkQuality: PLVNetworkQuality = PLVNetworkQuality.UNKNOWN
  @State private networkStatistics: PLVNetworkStatistics | undefined = undefined
  @State private networkStatisticsPopupVisible: boolean = false
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    this.sdk.linkmicManager.linkmicNetworkQuality.observe(it => this.networkQuality = it)
      .pushTo(this.observers)
    this.sdk.linkmicManager.linkmicNetworkStatistics.observe(it => this.networkStatistics = it)
      .pushTo(this.observers)
  }

  build() {
    Row() {
      Image(this.networkQualityIcon())
        .width(12)
        .height(12)

      Text(this.networkQualityText())
        .fontColor('#F0F1F5')
        .fontSize(12)
        .margin({
          left: 4
        })
    }
    .backgroundColor('#33000000')
    .borderRadius(10)
    .padding({
      left: 8,
      right: 8,
      top: 2,
      bottom: 2
    })
    .onClick(() => {
      if (this.networkStatistics !== undefined) {
        this.networkStatisticsPopupVisible = true
      }
    })
    .bindPopup(this.networkStatisticsPopupVisible, {
      builder: this.networkStatisticsPopup,
      placement: Placement.Bottom,
      backgroundBlurStyle: BlurStyle.NONE,
      popupColor: '#212121',
      radius: 16,
      onStateChange: (event) => {
        this.networkStatisticsPopupVisible = event.isVisible
      }
    })
  }

  private networkQualityIcon(): Resource {
    switch (this.networkQuality) {
      case PLVNetworkQuality.EXCELLENT:
      case PLVNetworkQuality.GOOD:
        return $r('app.media.plvsa_status_bar_network_quality_good_icon')
      case PLVNetworkQuality.POOR:
      case PLVNetworkQuality.BAD:
        return $r('app.media.plvsa_status_bar_network_quality_moderate_icon')
      case PLVNetworkQuality.VERY_BAD:
      case PLVNetworkQuality.DISCONNECT:
      case PLVNetworkQuality.UNKNOWN:
      default:
        return $r('app.media.plvsa_status_bar_network_quality_bad_icon')
    }
  }

  private networkQualityText(): Resource {
    switch (this.networkQuality) {
      case PLVNetworkQuality.EXCELLENT:
        return $r('app.string.plvsa_status_bar_network_quality_excellent')
      case PLVNetworkQuality.GOOD:
        return $r('app.string.plvsa_status_bar_network_quality_good')
      case PLVNetworkQuality.POOR:
        return $r('app.string.plvsa_status_bar_network_quality_poor')
      case PLVNetworkQuality.BAD:
        return $r('app.string.plvsa_status_bar_network_quality_bad')
      case PLVNetworkQuality.VERY_BAD:
        return $r('app.string.plvsa_status_bar_network_quality_very_bad')
      case PLVNetworkQuality.DISCONNECT:
        return $r('app.string.plvsa_status_bar_network_quality_disconnect')
      case PLVNetworkQuality.UNKNOWN:
      default:
        return $r('app.string.plvsa_status_bar_network_quality_unknown')
    }
  }

  @Builder
  private networkStatisticsPopup() {
    if (this.networkStatistics !== undefined) {
      Column() {
        Text($r('app.string.plvsa_status_bar_network_delay_text', this.networkStatistics.upDelayMs.toString()))
          .fontColor('#F0F1F5')
          .fontSize(14)
        Text($r('app.string.plvsa_status_bar_network_loss_rate_text', this.networkStatistics.upLossRate.toFixed(1), this.networkStatistics.downLossRate.toFixed(1)))
          .fontColor('#F0F1F5')
          .fontSize(14)
          .margin({
            top: 6
          })
      }
      .alignItems(HorizontalAlign.Start)
      .padding(12)
    }
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
    this.observers = []
  }
}