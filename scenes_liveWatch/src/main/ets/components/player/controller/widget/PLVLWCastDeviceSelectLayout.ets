import { PLVCommonConstants } from '@polyvharmony/live-scenes-sdk'
import { PLVMediaCastDevice, PLVMediaCastManager } from '@polyvharmony/media-cast'
import { lateInit, MutableObserver, runCatching, seconds, watchStates } from '@polyvharmony/media-player-sdk'
import { PLVLWLayoutDataBus } from '../../../../common/PLVLWLayoutDataBus'

@CustomDialog
export struct PLVLWCastDeviceSelectLayout {
  controller: CustomDialogController = lateInit()
  @Consume('layoutDataBus') layoutDataBus: PLVLWLayoutDataBus
  @State private isPortrait: boolean = true
  @State private devices: PLVMediaCastDevice[] = []
  @State private currentCastDevice: PLVMediaCastDevice | undefined = undefined
  @State private isScanningDevice: boolean = false
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    watchStates(() => {
      this.isPortrait = this.layoutDataBus.isPortrait.value ?? true
    }).pushTo(this.observers)
    watchStates(() => {
      this.devices = PLVMediaCastManager.getInstance().listenerRegistry.devices.value ?? []
    }).pushTo(this.observers)
    watchStates(() => {
      this.currentCastDevice = this.layoutDataBus.mediaCast.currentCastDevice.value ?? undefined
    }).pushTo(this.observers)

    this.runScanDevice()
  }

  build() {
    RelativeContainer() {
      Text($r('app.string.plvlw_cast_search_device_title'))
        .id('plvlw_cast_search_device_title')
        .fontColor('#333333')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .alignRules({
          middle: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Center },
          top: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Top }
        })
        .margin({
          top: 20
        })

      Text($r('app.string.plvlw_cast_search_device_result_title'))
        .id('plvlw_cast_search_device_result_title')
        .fontColor('#333333')
        .fontSize(14)
        .alignRules({
          top: { anchor: 'plvlw_cast_search_device_title', align: VerticalAlign.Bottom },
          left: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Start }
        })
        .margin({
          left: 15,
          top: 30
        })

      Image(this.isScanningDevice ? $r('app.media.plvlw_cast_searching') : $r('app.media.plvlw_cast_refresh'))
        .id('plvlw_cast_search_iv')
        .width(35)
        .height(35)
        .padding(5)
        .alignRules({
          center: { anchor: 'plvlw_cast_search_device_result_title', align: VerticalAlign.Center },
          right: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.End }
        })
        .margin({
          right: 15
        })
        .onClick(() => {
          this.runScanDevice()
        })

      Divider()
        .id('plvlw_cast_search_divider')
        .vertical(false)
        .width(PLVCommonConstants.CONTAINER)
        .height(1)
        .color('#E5E5E5')
        .alignRules({
          top: { anchor: 'plvlw_cast_search_device_result_title', align: VerticalAlign.Bottom }
        })
        .margin({
          top: 10
        })

      Image($r('app.media.plvlw_cast_search_bg_icon'))
        .width(125)
        .alignRules({
          left: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Start },
          bottom: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Bottom }
        })

      if (!this.isScanningDevice && this.devices.length == 0) {
        Column() {
          Image($r('app.media.plvlw_cast_no_device'))
            .width(250)

          Text($r('app.string.plvlw_cast_search_device_result_not_found'))
            .fontColor('#333333')
            .fontSize(16)
            .margin({
              top: 20
            })

          Text($r('app.string.plvlw_cast_search_device_retry'))
            .width(160)
            .height(40)
            .textAlign(TextAlign.Center)
            .fontColor('#FFFFFF')
            .fontSize(16)
            .backgroundColor('#56ACE9')
            .borderRadius(20)
            .margin({
              top: 12
            })
            .onClick(() => {
              this.runScanDevice()
            })
        }
        .width(PLVCommonConstants.FULL_PERCENT)
        .alignItems(HorizontalAlign.Center)
        .alignRules({
          top: { anchor: 'plvlw_cast_search_divider', align: VerticalAlign.Bottom }
        })
        .margin({
          top: this.isPortrait ? 90 : 10
        })
      } else {
        Stack() {
          Scroll() {
            Column() {
              ForEach(
                this.devices,
                (device: PLVMediaCastDevice) => {
                  Row() {
                    Image(this.isSameDevice(this.currentCastDevice, device) ? $r('app.media.plvlw_cast_device_white') : $r('app.media.plvlw_cast_device_black'))
                      .width(15)
                      .height(15)
                      .objectFit(ImageFit.Contain)
                      .margin({
                        left: 15
                      })

                    Text(device.friendlyName)
                      .fontColor(this.isSameDevice(this.currentCastDevice, device) ? '#FFFFFF' : '#000000')
                      .fontSize(16)
                      .layoutWeight(1)
                      .padding({
                        left: 15,
                        right: 15,
                        top: 12,
                        bottom: 12
                      })

                    if (this.isSameDevice(this.currentCastDevice, device)) {
                      Image($r('app.media.plvlw_cast_yes'))
                        .width(15)
                        .height(15)
                        .objectFit(ImageFit.Contain)
                        .margin({
                          right: 20
                        })
                    }
                  }
                  .width(PLVCommonConstants.CONTAINER)
                  .alignItems(VerticalAlign.Center)
                  .linearGradient(
                    this.isSameDevice(this.currentCastDevice, device) ?
                      {
                        angle: 90,
                        colors: [
                          ['#56ACE9', 0],
                          ['#8FD6F6', 1]
                        ]
                      }
                      : undefined
                  )
                  .borderRadius(4)
                  .margin({
                    left: 15,
                    right: 15,
                    top: 5
                  })
                  .onClick(() => {
                    if (!this.isSameDevice(this.currentCastDevice, device)) {
                      this.controller.close()
                      this.layoutDataBus.mediaCast.onStartCast.setValue(device)
                    }
                  })
                },
                (device: PLVMediaCastDevice) => device.location
              )
            }
          }
        }
        .width(PLVCommonConstants.FULL_PERCENT)
        .alignContent(Alignment.Top)
        .margin({
          top: 10
        })
        .padding({
          left: 15,
          right: 15
        })
        .alignRules({
          top: { anchor: 'plvlw_cast_search_divider', align: VerticalAlign.Bottom },
          bottom: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Bottom }
        })
      }
    }
    .width(this.isPortrait ? PLVCommonConstants.FULL_PERCENT : 375)
    .height(this.isPortrait ? '65%' : PLVCommonConstants.FULL_PERCENT)
    .borderRadius({
      topLeft: 16,
      topRight: this.isPortrait ? 16 : 0,
      bottomLeft: this.isPortrait ? 0 : 16
    })
    .backgroundColor('#FFFFFF')
  }

  private async runScanDevice() {
    if (this.isScanningDevice) {
      return
    }
    this.isScanningDevice = true
    await runCatching(PLVMediaCastManager.getInstance().scanDevices(seconds(5)))
    this.isScanningDevice = false
  }

  private isSameDevice(device1: PLVMediaCastDevice | null | undefined, device2: PLVMediaCastDevice | null | undefined): boolean {
    return device1?.location === device2?.location
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
    this.observers = []
  }
}