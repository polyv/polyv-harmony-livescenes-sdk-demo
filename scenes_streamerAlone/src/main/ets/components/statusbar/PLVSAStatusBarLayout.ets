import { PLVCommonConstants, PLVLiveSceneSDK } from '@polyvharmony/live-scenes-sdk';
import { lateInit } from '@polyvharmony/media-player-sdk';
import { PLVSAStatusChannelInfoBar } from './widgets/PLVSAStatusChannelInfoBar';
import { PLVSAStatusMemberCountBar } from './widgets/PLVSAStatusMemberCountBar';
import { PLVSAStatusNetworkBar } from './widgets/PLVSAStatusNetworkBar';
import { PLVSAStatusNotificationBar } from './widgets/PLVSAStatusNotificationBar';
import { PLVSAStatusStreamDurationBar } from './widgets/PLVSAStatusStreamDurationBar';
import { PLVSAStatusUserInfoBar } from './widgets/PLVSAStatusUserInfoBar';
import { display } from '@kit.ArkUI';
import { PLVSAConfirmDialog } from '../../common/widget/PLVSAConfirmDialog';
import { PLVSAPageDataBus } from '../../common/PLVSAPageDataBus';
import { PLVSAStatusPushDowngradeNotifyBar } from './widgets/PLVSAStatusPushDowngradeNotifyBar';

@Component
export struct PLVSAStatusBarLayout {
  build() {
    if (this.isPortrait()) {
      PLVSAStatusBarLayoutPort()
    } else {
      PLVSAStatusBarLayoutLand()
    }
  }

  private isPortrait(): boolean {
    const orientation = display.getDefaultDisplaySync().orientation
    return orientation === display.Orientation.PORTRAIT || orientation === display.Orientation.PORTRAIT_INVERTED
  }
}

@Component
struct PLVSAStatusBarLayoutPort {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @Consume('pageDataBus') pageDataBus: PLVSAPageDataBus
  private readonly finishStreamDialogController = new CustomDialogController({
    builder: PLVSAConfirmDialog({
      hasTitle: false,
      content: $r('app.string.plvsa_finish_stream_confirm_dialog_content'),
      onClickConfirm: (controller) => {
        this.pageDataBus.finishStream(this.sdk)
        controller?.close()
      }
    }),
    customStyle: true
  })

  build() {
    RelativeContainer() {
      PLVSAStatusChannelInfoBar()
        .id('plvsa_status_bar_channel_info_bar')
        .alignRules({
          top: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Top },
          left: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Start }
        })

      PLVSAStatusMemberCountBar()
        .id('plvsa_status_bar_member_count_bar')
        .alignRules({
          top: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Top },
          left: { anchor: 'plvsa_status_bar_channel_info_bar', align: HorizontalAlign.End }
        })
        .margin({
          left: 8
        })

      PLVSAStatusStreamDurationBar()
        .id('plvsa_status_bar_stream_duration_bar')
        .alignRules({
          top: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Top },
          left: { anchor: 'plvsa_status_bar_member_count_bar', align: HorizontalAlign.End }
        })
        .margin({
          left: 8
        })

      Image($r('app.media.plvsa_status_bar_close'))
        .id('plvsa_status_bar_finish_stream_icon')
        .width(32)
        .height(32)
        .alignRules({
          top: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Top },
          right: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.End }
        })
        .onClick(() => {
          this.finishStreamDialogController.open()
        })

      PLVSAStatusUserInfoBar()
        .id('plvsa_status_bar_user_info_bar')
        .alignRules({
          top: { anchor: 'plvsa_status_bar_channel_info_bar', align: VerticalAlign.Bottom },
          left: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Start }
        })
        .margin({
          top: 8
        })

      PLVSAStatusNetworkBar()
        .id('plvsa_status_bar_network_bar')
        .alignRules({
          top: { anchor: 'plvsa_status_bar_finish_stream_icon', align: VerticalAlign.Bottom },
          right: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.End }
        })
        .margin({
          top: 12
        })

      PLVSAStatusNotificationBar()
        .id('plvsa_status_bar_notification_bar')
        .alignRules({
          top: { anchor: 'plvsa_status_bar_user_info_bar', align: VerticalAlign.Bottom },
          left: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Start }
        })
        .margin({
          top: 16
        })

      PLVSAStatusPushDowngradeNotifyBar()
        .id('plvsa_status_bar_push_downgrade_notify')
        .alignRules({
          top: { anchor: 'plvsa_status_bar_notification_bar', align: VerticalAlign.Bottom },
          middle: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Center }
        })
        .margin({
          top: 8
        })

    }
    .width('100%')
    .height('100%')
    .padding(8)
  }
}

@Component
struct PLVSAStatusBarLayoutLand {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @Consume('pageDataBus') pageDataBus: PLVSAPageDataBus
  private readonly finishStreamDialogController = new CustomDialogController({
    builder: PLVSAConfirmDialog({
      hasTitle: false,
      content: $r('app.string.plvsa_finish_stream_confirm_dialog_content'),
      onClickConfirm: (controller) => {
        this.pageDataBus.finishStream(this.sdk)
        controller?.close()
      }
    }),
    customStyle: true
  })

  build() {
    RelativeContainer() {
      PLVSAStatusChannelInfoBar()
        .id('plvsa_status_bar_channel_info_bar')
        .alignRules({
          top: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Top },
          left: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Start }
        })

      PLVSAStatusMemberCountBar()
        .id('plvsa_status_bar_member_count_bar')
        .alignRules({
          top: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Top },
          left: { anchor: 'plvsa_status_bar_channel_info_bar', align: HorizontalAlign.End }
        })
        .margin({
          left: 8
        })

      PLVSAStatusStreamDurationBar()
        .id('plvsa_status_bar_stream_duration_bar')
        .alignRules({
          top: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Top },
          left: { anchor: 'plvsa_status_bar_member_count_bar', align: HorizontalAlign.End }
        })
        .margin({
          left: 8
        })

      Image($r('app.media.plvsa_status_bar_close'))
        .id('plvsa_status_bar_finish_stream_icon')
        .width(32)
        .height(32)
        .alignRules({
          top: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Top },
          right: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.End }
        })
        .onClick(() => {
          this.finishStreamDialogController.open()
        })

      PLVSAStatusUserInfoBar()
        .id('plvsa_status_bar_user_info_bar')
        .alignRules({
          top: { anchor: 'plvsa_status_bar_channel_info_bar', align: VerticalAlign.Bottom },
          left: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Start }
        })
        .margin({
          top: 8
        })

      PLVSAStatusNetworkBar()
        .id('plvsa_status_bar_network_bar')
        .alignRules({
          center: { anchor: 'plvsa_status_bar_finish_stream_icon', align: VerticalAlign.Center },
          right: { anchor: 'plvsa_status_bar_finish_stream_icon', align: HorizontalAlign.Start }
        })
        .margin({
          right: 8
        })

      PLVSAStatusNotificationBar()
        .id('plvsa_status_bar_notification_bar')
        .alignRules({
          top: { anchor: 'plvsa_status_bar_user_info_bar', align: VerticalAlign.Bottom },
          left: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Start }
        })
        .margin({
          top: 16
        })

      PLVSAStatusPushDowngradeNotifyBar()
        .id('plvsa_status_bar_push_downgrade_notify')
        .alignRules({
          top: { anchor: 'plvsa_status_bar_notification_bar', align: VerticalAlign.Bottom },
          middle: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Center }
        })
        .margin({
          top: 8
        })

    }
    .width('100%')
    .height('100%')
    .padding(8)
  }
}