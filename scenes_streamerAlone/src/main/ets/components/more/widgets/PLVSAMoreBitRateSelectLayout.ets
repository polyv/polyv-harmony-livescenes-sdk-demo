import {
  PLVCommonConstants,
  PLVLinkMicBitRate,
  PLVLinkMicBitRateEncodeParam,
  PLVLiveSceneSDK
} from '@polyvharmony/live-scenes-sdk'
import { lateInit, MutableObserver, toRaw } from '@polyvharmony/media-player-sdk'
import { PLVSAPreferenceCardView } from '../../../common/widget/PLVSAPreferenceCardView'
import { display } from '@kit.ArkUI'
import { PLVSAPageDataBus } from '../../../common/PLVSAPageDataBus'

@CustomDialog
export struct PLVSAMoreBitRateSelectLayout {
  controller: CustomDialogController = lateInit()

  build() {
    if (this.isPortrait()) {
      PLVSAMoreBitRateSelectLayoutPort({
        closeController: () => {
          this.controller.close()
        }
      })
    } else {
      PLVSAMoreBitRateSelectLayoutLand({
        closeController: () => {
          this.controller.close()
        }
      })
    }
  }

  private isPortrait(): boolean {
    const orientation = display.getDefaultDisplaySync().orientation
    return orientation === display.Orientation.PORTRAIT || orientation === display.Orientation.PORTRAIT_INVERTED
  }
}

@Component
struct PLVSAMoreBitRateSelectLayoutPort {
  closeController: () => void = lateInit()
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @Consume('pageDataBus') pageDataBus: PLVSAPageDataBus
  @State private currentBitRate: PLVLinkMicBitRate = PLVLinkMicBitRate.STANDARD
  @State private supportBitRateEncodeParam: PLVLinkMicBitRateEncodeParam[] = []
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    this.sdk.streamerManager.currentBitRate.observe(it => this.currentBitRate = it)
      .pushTo(this.observers)
    this.sdk.streamerManager.channelSupportBitRateEncodeParams.observe(it => this.supportBitRateEncodeParam = it)
      .pushTo(this.observers)
  }

  build() {
    Column() {
      Text($r('app.string.plvsa_more_bitrate_select_title'))
        .fontColor('#F0F1F5')
        .fontSize(18)
        .margin({
          left: 32,
          top: 32
        })

      Scroll() {
        Column() {
          ForEach(
            this.supportBitRateEncodeParam,
            (encodeParam: PLVLinkMicBitRateEncodeParam) => {
              PLVSAMoreBitRateSelectItem({
                encodeParam: encodeParam,
                selected: encodeParam.bitRate === toRaw(this.currentBitRate)
              })
                .margin({
                  left: 32,
                  right: 32,
                  top: 6,
                  bottom: 6
                })
                .onClick(() => {
                  const selected = encodeParam.bitRate === toRaw(this.currentBitRate)
                  if (!selected) {
                    this.sdk.streamerManager.setBitRate(encodeParam.bitRate)
                    this.pageDataBus.recoverSetting.update({
                      bitRateIndex: encodeParam.bitRate.index
                    })
                    this.closeController()
                  }
                })
            },
            (encodeParam: PLVLinkMicBitRateEncodeParam) => encodeParam.bitRate.index.toString()
          )

          Blank().height(12)
        }
      }
      .width('100%')
      .height(300)
      .align(Alignment.Top)
      .scrollable(ScrollDirection.Vertical)
      .scrollBar(BarState.Off)
      .margin({
        top: 26
      })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .backgroundColor('#2c2c2c')
    .borderRadius({
      topLeft: 16,
      topRight: 16
    })
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
    this.observers = []
  }
}

@Component
struct PLVSAMoreBitRateSelectLayoutLand {
  closeController: () => void = lateInit()
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @Consume('pageDataBus') pageDataBus: PLVSAPageDataBus
  @State private currentBitRate: PLVLinkMicBitRate = PLVLinkMicBitRate.STANDARD
  @State private supportBitRateEncodeParam: PLVLinkMicBitRateEncodeParam[] = []
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    this.sdk.streamerManager.currentBitRate.observe(it => this.currentBitRate = it)
      .pushTo(this.observers)
    this.sdk.streamerManager.channelSupportBitRateEncodeParams.observe(it => this.supportBitRateEncodeParam = it)
      .pushTo(this.observers)
  }

  build() {
    RelativeContainer() {
      Text($r('app.string.plvsa_more_bitrate_select_title'))
        .id('plvsa_more_bitrate_select_title')
        .fontColor('#F0F1F5')
        .fontSize(18)
        .margin({
          left: 32,
          top: 32
        })
        .alignRules({
          top: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Top },
          left: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Start }
        })

      Scroll() {
        Column() {
          ForEach(
            this.supportBitRateEncodeParam,
            (encodeParam: PLVLinkMicBitRateEncodeParam) => {
              PLVSAMoreBitRateSelectItem({
                encodeParam: encodeParam,
                selected: encodeParam.bitRate === toRaw(this.currentBitRate)
              })
                .margin({
                  left: 32,
                  right: 32,
                  top: 6,
                  bottom: 6
                })
                .onClick(() => {
                  const selected = encodeParam.bitRate === toRaw(this.currentBitRate)
                  if (!selected) {
                    this.sdk.streamerManager.setBitRate(encodeParam.bitRate)
                    this.pageDataBus.recoverSetting.update({
                      bitRateIndex: encodeParam.bitRate.index
                    })
                    this.closeController()
                  }
                })
            },
            (encodeParam: PLVLinkMicBitRateEncodeParam) => encodeParam.bitRate.index.toString()
          )

          Blank().height(12)
        }
      }
      .id('plvsa_more_bitrate_select_container')
      .width('100%')
      .align(Alignment.Top)
      .scrollable(ScrollDirection.Vertical)
      .scrollBar(BarState.Off)
      .margin({
        top: 26
      })
      .alignRules({
        top: { anchor: 'plvsa_more_bitrate_select_title', align: VerticalAlign.Bottom },
        bottom: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Bottom }
      })
    }
    .width(304)
    .height('100%')
    .backgroundColor('#2c2c2c')
    .borderRadius({
      topLeft: 16,
      bottomLeft: 16
    })
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
    this.observers = []
  }
}

@Component
struct PLVSAMoreBitRateSelectItem {
  encodeParam: PLVLinkMicBitRateEncodeParam = lateInit()
  @Prop selected: boolean = false

  build() {
    PLVSAPreferenceCardView({
      slot: () => {
        this.bitRateDescriptionContent()
      },
      selected: this.selected
    })
  }

  @Builder
  private bitRateDescriptionContent() {
    Column() {
      Text(this.encodeParam.bitRate.name)
        .fontSize(16)
        .fontColor('#F0F1F5')
      Text($r('app.string.plvsa_more_bitrate_description_text', `${this.encodeParam.videoWidth}p`, `${this.encodeParam.videoBitrate}kbps`, `${this.encodeParam.videoFps}fps`))
        .fontSize(12)
        .fontColor('#99F0F1F5')
        .margin({
          top: 4
        })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding({
      left: 20,
      right: 20,
      top: 12,
      bottom: 12
    })
  }
}