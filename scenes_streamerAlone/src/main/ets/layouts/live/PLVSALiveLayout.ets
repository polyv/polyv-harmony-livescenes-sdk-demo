import {
  PLVCommonConstants,
  PLVLinkMicAnswerInvitationEvent,
  PLVLiveSceneSDK,
  PLVMemberErrorEvent,
  PLVToastUtils
} from '@polyvharmony/live-scenes-sdk';
import { Disposable, lateInit, MutableObserver } from '@polyvharmony/media-player-sdk';
import { PLVSAPageDataBus } from '../../common/PLVSAPageDataBus';
import { PLVSAConfirmDialog } from '../../common/widget/PLVSAConfirmDialog';
import { PLVSAChatroomLayout } from '../../components/chatroom/PLVSAChatroomLayout';
import { PLVSALinkMicInvitationLayout } from '../../components/linkmic/widgets/PLVSALinkMicInvitationLayout';
import { PLVSANetworkDisconnectMaskLayout } from '../../components/misc/PLVSANetworkDisconnectMaskLayout';
import { PLVSAStatusBarLayout } from '../../components/statusbar/PLVSAStatusBarLayout';
import { PLVSAToolBarLayout } from '../../components/toolbar/PLVSAToolBarLayout';

@Component
export struct PLVSALiveLayout {
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
  private maskLayoutOnTouchIntercept: ((touchEvent: TouchEvent) => HitTestMode) | undefined = undefined
  private onBackPressDisposable: Disposable | null = null

  aboutToAppear(): void {
    this.sdk.memberManager.startUpdateChannelViewersInterval()
    this.onBackPressDisposable = this.pageDataBus.onBackPressHandler.register(10, () => this.onBackPress())
  }

  build() {
    Stack() {
      LiveEventHandler()

      Tabs({
        index: 1
      }) {
        TabContent() {
          LiveClearLayout()
        }

        TabContent() {
          LiveMainLayout()
        }
      }
      .barHeight(0)
      .width('100%')
      .height('100%')

      PLVSANetworkDisconnectMaskLayout({
        callbackOnTouchIntercept: (callback: (touchEvent: TouchEvent) => HitTestMode) => {
          this.maskLayoutOnTouchIntercept = callback
        }
      })
        .id('plvsa_network_disconnect_mask_layout')
        .width('100%')
        .height('100%')
        .onTouchIntercept((event: TouchEvent) => {
          return this.maskLayoutOnTouchIntercept?.(event) ?? HitTestMode.Transparent
        })
    }
  }

  onBackPress(): boolean {
    this.finishStreamDialogController.open()
    return true
  }

  aboutToDisappear(): void {
    this.onBackPressDisposable?.dispose()
    this.sdk.memberManager.stopUpdateChannelViewersInterval()
  }
}

@Component
struct LiveMainLayout {
  build() {
    RelativeContainer() {
      PLVSAStatusBarLayout()
        .id('plvsa_status_bar_layout')
        .width('100%')
        .height('100%')
        .hitTestBehavior(HitTestMode.Transparent)

      PLVSAToolBarLayout()
        .id('plvsa_tool_bar')
        .margin({
          right: 8,
          bottom: 8
        })
        .alignRules({
          right: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.End },
          bottom: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Bottom }
        })
        .hitTestBehavior(HitTestMode.Transparent)

      PLVSAChatroomLayout()
        .id('plvsa_chatroom_layout')
        .width('100%')
        .height('100%')
        .alignRules({
          left: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Start },
          bottom: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Bottom }
        })
        .hitTestBehavior(HitTestMode.Transparent)

      PLVSALinkMicInvitationLayout()
        .id('plvsa_linkmic_invitation_layout')
        .width('100%')
        .height('100%')
        .hitTestBehavior(HitTestMode.Transparent)
    }
    .width('100%')
    .height('100%')
  }
}

@Component
struct LiveClearLayout {
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
      Image($r('app.media.plvsa_status_bar_close'))
        .id('plvsa_status_bar_finish_stream_icon')
        .width(32)
        .height(32)
        .alignRules({
          top: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Top },
          right: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.End }
        })
        .margin({
          top: 8,
          right: 8
        })
        .onClick(() => {
          this.finishStreamDialogController.open()
        })
    }
    .width('100%')
    .height('100%')
  }
}

@Component
struct LiveEventHandler {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    this.sdk.linkmicManager.viewerAnswerInvitationEvent.observe(it => this.onLinkMicViewerAnswerInvitation(it))
      .pushTo(this.observers)
    this.sdk.memberManager.errorEvent.observe(it => this.onMemberErrorEvent(it))
      .pushTo(this.observers)
  }

  build() {
  }

  private onLinkMicViewerAnswerInvitation(event: PLVLinkMicAnswerInvitationEvent) {
    const viewerName = event.viewer.viewerName.value
    const accept = event.accept
    if (viewerName !== undefined && !accept) {
      PLVToastUtils.shortShow($r('app.string.plvsa_linkmic_invitation_not_accept', viewerName))
    }
  }

  private onMemberErrorEvent(event: PLVMemberErrorEvent) {
    switch (event.code) {
      case PLVMemberErrorEvent.REACH_LINKMIC_LIMIT: {
        PLVToastUtils.shortShow($r('app.string.plvsa_linkmic_reach_limit'));
        break;
      }
      default:
    }
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
    this.observers = []
  }
}