import { PLVLinkMicBitRate, PLVLiveSceneSDK } from '@polyvharmony/live-scenes-sdk';
import { lateInit, MutableObserver, toRaw } from '@polyvharmony/media-player-sdk';
import { PLVSAMoreBitRateSelectLayout } from './PLVSAMoreBitRateSelectLayout';

@Component
export struct PLVSAMoreBitRateButton {
  iconPadding: number = 8
  onClicked: (origin: () => void) => void = (origin) => {
    origin()
  }
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  private readonly bitRateSelectController: CustomDialogController = new CustomDialogController({
    builder: PLVSAMoreBitRateSelectLayout(),
    alignment: DialogAlignment.BottomEnd,
    customStyle: true
  })
  @State private currentBitRate: PLVLinkMicBitRate = PLVLinkMicBitRate.STANDARD
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    this.sdk.streamerManager.currentBitRate.observe((bitRate) => this.currentBitRate = bitRate)
      .pushTo(this.observers)
  }

  build() {
    Column() {
      Image(this.bitRateIcon())
        .width(48)
        .height(48)
        .padding(this.iconPadding)
        .objectFit(ImageFit.Contain)
      Text(this.currentBitRate.name)
        .fontColor("#FFFFFF")
        .fontSize(12)
        .textAlign(TextAlign.Center)
    }
    .onClick(() => {
      this.onClicked(() => {
        this.bitRateSelectController.open()
      })
    })
  }

  private bitRateIcon(): Resource {
    switch (toRaw(this.currentBitRate)) {
      case PLVLinkMicBitRate.STANDARD:
      default:
        return $r("app.media.plvsa_more_bitrate_icon_standard")
      case PLVLinkMicBitRate.HIGH:
        return $r("app.media.plvsa_more_bitrate_icon_high")
      case PLVLinkMicBitRate.SUPER:
        return $r("app.media.plvsa_more_bitrate_icon_super")
      case PLVLinkMicBitRate.SUPER_HIGH:
        return $r("app.media.plvsa_more_bitrate_icon_super_high")
    }
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
    this.observers = []
  }
}