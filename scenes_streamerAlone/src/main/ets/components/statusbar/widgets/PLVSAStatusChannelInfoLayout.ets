import { PLVCommonConstants, PLVLiveSceneSDK, PLVToastUtils, PLVUtils } from '@polyvharmony/live-scenes-sdk';
import { isTextBlank, lateInit } from '@polyvharmony/media-player-sdk';
import { display } from '@kit.ArkUI';

@CustomDialog
export struct PLVSAStatusChannelInfoLayout {
  controller: CustomDialogController = lateInit()

  build() {
    if (this.isPortrait()) {
      PLVSAStatusChannelInfoLayoutPort()
    } else {
      PLVSAStatusChannelInfoLayoutLand()
    }
  }

  private isPortrait(): boolean {
    const orientation = display.getDefaultDisplaySync().orientation
    return orientation === display.Orientation.PORTRAIT || orientation === display.Orientation.PORTRAIT_INVERTED
  }
}

@Component
struct PLVSAStatusChannelInfoLayoutPort {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @State private liveTitle: string = ""
  @State private startTime: string | Resource = $r('app.string.plvsa_status_bar_channel_info_start_time_not_set')
  @State private channelId: string = ""

  aboutToAppear(): void {
    this.liveTitle = this.sdk.channelData.streamerData?.channelName ?? ""
    const startTime = this.sdk.channelData.liveDetail?.startTime?.toString?.() ?? ""
    if (!isTextBlank(startTime)) {
      this.startTime = startTime
    }
    this.channelId = this.sdk.channelData.loginChannelId?.toString() ?? ""
  }

  build() {
    Column() {
      Text($r('app.string.plvsa_status_bar_channel_info'))
        .fontColor('#F0F1F5')
        .fontSize(18)

      Row() {
        Text($r('app.string.plvsa_status_bar_channel_info_live_title'))
          .fontColor('#99F0F1F5')
          .fontSize(14)
        Text(this.liveTitle)
          .fontColor('#F0F1F5')
          .fontSize(14)
          .layoutWeight(1)
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)
      .margin({
        top: 22
      })

      Row() {
        Text($r('app.string.plvsa_status_bar_channel_info_start_time'))
          .fontColor('#99F0F1F5')
          .fontSize(14)
        Text(this.startTime)
          .fontColor('#F0F1F5')
          .fontSize(14)
      }
      .margin({
        top: 12
      })

      Row() {
        Text($r('app.string.plvsa_status_bar_channel_info_channel_id'))
          .fontColor('#99F0F1F5')
          .fontSize(14)
        Text(this.channelId)
          .fontColor('#F0F1F5')
          .fontSize(14)
        Text($r('app.string.plvsa_status_bar_channel_info_copy'))
          .fontColor('#FFFFFF')
          .fontSize(12)
          .padding({
            left: 12,
            right: 12,
            top: 6,
            bottom: 6
          })
          .margin({
            left: 12
          })
          .borderRadius(16)
          .linearGradient({
            angle: 90,
            colors: [
              ['#0080FF', 0],
              ['#3399FF', 1]
            ]
          })
          .onClick(async () => {
            await PLVUtils.copyText(this.channelId);
            PLVToastUtils.shortShow($r('app.string.plvsa_status_bar_channel_info_copy_success'))
          })
      }
      .margin({
        top: 12
      })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .borderRadius({
      topLeft: 16,
      topRight: 16
    })
    .backgroundColor('#2c2c2c')
    .padding(32)
  }
}

@Component
struct PLVSAStatusChannelInfoLayoutLand {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @State private liveTitle: string = ""
  @State private startTime: string | Resource = $r('app.string.plvsa_status_bar_channel_info_start_time_not_set')
  @State private channelId: string = ""

  aboutToAppear(): void {
    this.liveTitle = this.sdk.channelData.streamerData?.channelName ?? ""
    const startTime = this.sdk.channelData.liveDetail?.startTime?.toString?.() ?? ""
    if (!isTextBlank(startTime)) {
      this.startTime = startTime
    }
    this.channelId = this.sdk.channelData.loginChannelId?.toString() ?? ""
  }

  build() {
    RelativeContainer() {
      Text($r('app.string.plvsa_status_bar_channel_info'))
        .id('plvsa_status_bar_channel_info_title')
        .fontColor('#F0F1F5')
        .fontSize(18)

      Scroll() {
        Column() {
          Text($r('app.string.plvsa_status_bar_channel_info_live_title'))
            .fontColor('#99F0F1F5')
            .fontSize(14)
            .margin({
              top: 6
            })

          Text(this.liveTitle)
            .fontColor('#F0F1F5')
            .fontSize(14)
            .margin({
              top: 6
            })

          Text($r('app.string.plvsa_status_bar_channel_info_start_time'))
            .fontColor('#99F0F1F5')
            .fontSize(14)
            .margin({
              top: 12
            })

          Text(this.startTime)
            .fontColor('#F0F1F5')
            .fontSize(14)
            .margin({
              top: 6
            })

          Text($r('app.string.plvsa_status_bar_channel_info_channel_id'))
            .fontColor('#99F0F1F5')
            .fontSize(14)
            .margin({
              top: 12
            })

          Row() {
            Text(this.channelId)
              .fontColor('#F0F1F5')
              .fontSize(14)
            Text($r('app.string.plvsa_status_bar_channel_info_copy'))
              .fontColor('#FFFFFF')
              .fontSize(12)
              .padding({
                left: 12,
                right: 12,
                top: 6,
                bottom: 6
              })
              .margin({
                left: 12
              })
              .borderRadius(16)
              .linearGradient({
                angle: 90,
                colors: [
                  ['#0080FF', 0],
                  ['#3399FF', 1]
                ]
              })
              .onClick(async () => {
                await PLVUtils.copyText(this.channelId);
                PLVToastUtils.shortShow($r('app.string.plvsa_status_bar_channel_info_copy_success'))
              })
          }
          .margin({
            top: 6
          })

          Blank().height(16)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }
      .id('plvsa_status_bar_channel_info_container')
      .width('100%')
      .align(Alignment.Top)
      .alignRules({
        top: { anchor: 'plvsa_status_bar_channel_info_title', align: VerticalAlign.Bottom },
        bottom: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Bottom }
      })
      .margin({
        top: 16
      })
    }
    .width(300)
    .height('100%')
    .borderRadius({
      topLeft: 16,
      bottomLeft: 16
    })
    .backgroundColor('#2c2c2c')
    .padding(32)
  }
}