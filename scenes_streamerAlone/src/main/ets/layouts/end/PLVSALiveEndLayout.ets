import { PLVCommonConstants, PLVLiveSceneSDK, PLVTimeUtils, PLVUserType } from '@polyvharmony/live-scenes-sdk';
import { extendNumber, lateInit } from '@polyvharmony/media-player-sdk';
import { display, router } from '@kit.ArkUI';

@Component
export struct PLVSALiveEndLayout {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()

  aboutToAppear(): void {
    const isGuest = this.sdk.channelData.viewerType === PLVUserType.USERTYPE_GUEST
    if (isGuest) {
      router.back()
    }
  }

  build() {
    if (this.isPortrait()) {
      PLVSALiveEndLayoutPort()
    } else {
      PLVSALiveEndLayoutLand()
    }
  }

  private isPortrait(): boolean {
    const orientation = display.getDefaultDisplaySync().orientation
    return orientation === display.Orientation.PORTRAIT || orientation === display.Orientation.PORTRAIT_INVERTED
  }
}

@Component
struct PLVSALiveEndLayoutPort {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  private liveTimestampRange: string = ""
  private liveTimeDuration: string = ""

  aboutToAppear(): void {
    const start = new Date()
    const current = new Date()
    const liveStartTimestamp = this.sdk.streamerManager.liveStartTimestamp.value ?? current.getTime()
    const liveEndTimestamp = current.getTime()
    start.setTime(liveStartTimestamp)

    const pad = (num: number) => num.toString().padStart(2, '0')
    const startTimeStr = `${pad(start.getHours())}:${pad(start.getMinutes())}:${pad(start.getSeconds())}`
    const endTimeStr = `${pad(current.getHours())}:${pad(current.getMinutes())}:${pad(current.getSeconds())}`
    this.liveTimestampRange = `${startTimeStr}～${endTimeStr}`
    const liveDuration = extendNumber(liveEndTimestamp - liveStartTimestamp).coerceAtLeast_ext(0)
    this.liveTimeDuration = PLVTimeUtils.generateTime(liveDuration, true)
  }

  build() {
    RelativeContainer() {
      Image($r('app.media.plvsa_streamer_finish_icon'))
        .id('plvsa_live_end_icon')
        .width(100)
        .height(84)
        .objectFit(ImageFit.Contain)
        .alignRules({
          top: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Top },
          middle: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Center }
        })
        .margin({
          top: 69
        })

      Text($r('app.string.plvsa_live_end_text'))
        .id('plvsa_live_end_text')
        .fontSize(24)
        .fontColor('#F0F1F5')
        .alignRules({
          top: { anchor: 'plvsa_live_end_icon', align: VerticalAlign.Bottom },
          middle: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Center }
        })
        .margin({
          top: 6
        })

      Shape()
        .id('plvsa_live_end_time_split')
        .width(1)
        .height(52)
        .backgroundColor('#33FFFFFF')
        .alignRules({
          top: { anchor: 'plvsa_live_end_text', align: VerticalAlign.Bottom },
          middle: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Center }
        })
        .margin({
          top: 40
        })

      Column() {
        Text(this.liveTimestampRange)
          .fontColor('#CCF0F1F5')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
        Blank().height(10)
        Text($r('app.string.plvsa_live_timestamp_text'))
          .fontColor('#CCF0F1F5')
          .fontSize(14)
      }
      .id('plvsa_live_end_timestamp_range')
      .alignRules({
        left: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Start },
        right: { anchor: 'plvsa_live_end_time_split', align: HorizontalAlign.Start },
        center: { anchor: 'plvsa_live_end_time_split', align: VerticalAlign.Center }
      })

      Column() {
        Text(this.liveTimeDuration)
          .fontColor('#CCF0F1F5')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
        Blank().height(10)
        Text($r('app.string.plvsa_live_duration_text'))
          .fontColor('#CCF0F1F5')
          .fontSize(14)
      }
      .id('plvsa_live_end_duration_range')
      .alignRules({
        left: { anchor: 'plvsa_live_end_time_split', align: HorizontalAlign.End },
        right: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.End },
        center: { anchor: 'plvsa_live_end_time_split', align: VerticalAlign.Center }
      })

      Button($r('app.string.plvsa_confirm_dialog_confirm'))
        .width(180)
        .height(50)
        .fontSize(16)
        .fontColor('#FFFFFF')
        .linearGradient({
          angle: 90,
          colors: [
            ['#0080FF', 0],
            ['#3399FF', 0]
          ]
        })
        .borderRadius(25)
        .alignRules({
          bottom: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Bottom },
          middle: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Center }
        })
        .margin({
          bottom: 119
        })
        .onClick(() => {
          router.back()
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#2c2c2c')
  }
}

@Component
struct PLVSALiveEndLayoutLand {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  private liveTimestampRange: string = ""
  private liveTimeDuration: string = ""

  aboutToAppear(): void {
    const start = new Date()
    const current = new Date()
    const liveStartTimestamp = this.sdk.streamerManager.liveStartTimestamp.value ?? current.getTime()
    const liveEndTimestamp = current.getTime()
    start.setTime(liveStartTimestamp)

    const pad = (num: number) => num.toString().padStart(2, '0')
    const startTimeStr = `${pad(start.getHours())}:${pad(start.getMinutes())}:${pad(start.getSeconds())}`
    const endTimeStr = `${pad(current.getHours())}:${pad(current.getMinutes())}:${pad(current.getSeconds())}`
    this.liveTimestampRange = `${startTimeStr}～${endTimeStr}`
    const liveDuration = extendNumber(liveEndTimestamp - liveStartTimestamp).coerceAtLeast_ext(0)
    this.liveTimeDuration = PLVTimeUtils.generateTime(liveDuration, true)
  }

  build() {
    RelativeContainer() {
      Image($r('app.media.plvsa_streamer_finish_icon'))
        .id('plvsa_live_end_icon')
        .width(100)
        .height(84)
        .objectFit(ImageFit.Contain)
        .alignRules({
          top: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Top },
          middle: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Center }
        })
        .margin({
          top: 38
        })

      Text($r('app.string.plvsa_live_end_text'))
        .id('plvsa_live_end_text')
        .fontSize(24)
        .fontColor('#F0F1F5')
        .alignRules({
          top: { anchor: 'plvsa_live_end_icon', align: VerticalAlign.Bottom },
          middle: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Center }
        })
        .margin({
          top: 6
        })

      Shape()
        .id('plvsa_live_end_time_split')
        .width(1)
        .height(52)
        .backgroundColor('#33FFFFFF')
        .alignRules({
          top: { anchor: 'plvsa_live_end_text', align: VerticalAlign.Bottom },
          middle: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Center }
        })
        .margin({
          top: 18
        })

      Column() {
        Text(this.liveTimestampRange)
          .fontColor('#CCF0F1F5')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
        Blank().height(10)
        Text($r('app.string.plvsa_live_timestamp_text'))
          .fontColor('#CCF0F1F5')
          .fontSize(14)
      }
      .id('plvsa_live_end_timestamp_range')
      .alignRules({
        right: { anchor: 'plvsa_live_end_time_split', align: HorizontalAlign.Start },
        center: { anchor: 'plvsa_live_end_time_split', align: VerticalAlign.Center }
      })
      .margin({
        right: 25
      })

      Column() {
        Text(this.liveTimeDuration)
          .fontColor('#CCF0F1F5')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
        Blank().height(10)
        Text($r('app.string.plvsa_live_duration_text'))
          .fontColor('#CCF0F1F5')
          .fontSize(14)
      }
      .id('plvsa_live_end_duration_range')
      .alignRules({
        left: { anchor: 'plvsa_live_end_time_split', align: HorizontalAlign.End },
        center: { anchor: 'plvsa_live_end_time_split', align: VerticalAlign.Center }
      })
      .margin({
        left: 40
      })

      Button($r('app.string.plvsa_confirm_dialog_confirm'))
        .width(180)
        .height(50)
        .fontSize(16)
        .fontColor('#FFFFFF')
        .linearGradient({
          angle: 90,
          colors: [
            ['#0080FF', 0],
            ['#3399FF', 0]
          ]
        })
        .borderRadius(25)
        .alignRules({
          bottom: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Bottom },
          middle: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Center }
        })
        .margin({
          bottom: 44
        })
        .onClick(() => {
          router.back()
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#2c2c2c')
  }
}