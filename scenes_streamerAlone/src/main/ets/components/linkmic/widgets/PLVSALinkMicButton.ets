import {
  PLVLinkMicMode,
  PLVLinkMicState,
  PLVLiveSceneSDK,
  PLVToastUtils,
  PLVUserType
} from '@polyvharmony/live-scenes-sdk';
import { lateInit, MutableObserver } from '@polyvharmony/media-player-sdk';
import { PLVSAConfirmDialog } from '../../../common/widget/PLVSAConfirmDialog';

@Component
export struct PLVSALinkMicButton {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @State private isTeacher: boolean = true

  aboutToAppear(): void {
    this.isTeacher = this.sdk.channelData.viewerType === PLVUserType.USERTYPE_TEACHER
  }

  build() {
    if (this.isTeacher) {
      LinkMicButtonTeacher()
    } else {
      LinkMicButtonGuest()
    }
  }

  aboutToDisappear(): void {
  }
}

@Component
struct LinkMicButtonTeacher {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  private readonly closeLinkMicDialogController = new CustomDialogController({
    builder: PLVSAConfirmDialog({
      title: $r('app.string.plvsa_linkmic_close_confirm_title'),
      content: $r('app.string.plvsa_linkmic_close_confirm_content'),
      onClickConfirm: (controller) => {
        this.sdk.linkmicManager.closeLinkMic()
        controller?.close()
      }
    }),
    customStyle: true
  })
  @State private isVisible: boolean = true
  @State private isOpenLinkMic: boolean = false
  @State private linkmicModeSelectPopupVisible: boolean = false
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    this.sdk.linkmicManager.isLinkMicStrategyV2.observe(isLinkMicStrategyV2 => {
      this.isVisible = !isLinkMicStrategyV2
    })
      .pushTo(this.observers)
    this.sdk.linkmicManager.channelAllowRequestHandsUpLinkMic.observe(it => this.isOpenLinkMic = it)
      .pushTo(this.observers)
  }

  build() {
    if (this.isVisible) {
      Image(this.isOpenLinkMic ? $r('app.media.plvsa_linkmic_button_to_close') : $r('app.media.plvsa_linkmic_button_to_open'))
        .width(36)
        .height(36)
        .onClick(() => {
          if (!this.isOpenLinkMic) {
            this.linkmicModeSelectPopupVisible = true
          } else {
            this.closeLinkMicDialogController.open()
          }
        })
        .bindPopup(this.linkmicModeSelectPopupVisible, {
          builder: this.linkmicModeSelectPopup,
          placement: Placement.Top,
          backgroundBlurStyle: BlurStyle.NONE,
          popupColor: '#BF1B202D',
          radius: 8,
          onStateChange: (event) => {
            this.linkmicModeSelectPopupVisible = event.isVisible
          }
        })
    }
  }

  @Builder
  linkmicModeSelectPopup() {
    Column() {
      Text($r('app.string.plvsa_linkmic_mode_video'))
        .fontSize(14)
        .fontColor('#F0F1F5')
        .padding(8)
        .onClick(() => {
          this.openLinkMic(PLVLinkMicMode.VIDEO)
          this.linkmicModeSelectPopupVisible = false
        })

      Shape()
        .width('calc(100% - 24vp)')
        .height(1)
        .margin({
          left: 12,
          right: 12,
          top: 2,
          bottom: 2
        })
        .backgroundColor('#4D1B202D')

      Text($r('app.string.plvsa_linkmic_mode_audio'))
        .fontSize(14)
        .fontColor('#F0F1F5')
        .padding(8)
        .onClick(() => {
          this.openLinkMic(PLVLinkMicMode.AUDIO)
          this.linkmicModeSelectPopupVisible = false
        })
    }
    .width(106)
    .padding({
      top: 6,
      bottom: 6
    })
  }

  private openLinkMic(linkmicMode: PLVLinkMicMode) {
    const channelLinkMicSettingEnable = (this.sdk.channelData.streamerData?.InteractNumLimit ?? 0) > 0
    if (!channelLinkMicSettingEnable) {
      PLVToastUtils.shortShow($r('app.string.plvsa_linkmic_setting_not_open'));
      return
    }
    this.sdk.linkmicManager.setLinkMicMode(linkmicMode)
    this.sdk.linkmicManager.openLinkMic()
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
    this.observers = []
  }
}

@Component
struct LinkMicButtonGuest {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @State private isVisible: boolean = true
  @State private linkmicState: PLVLinkMicState = PLVLinkMicState.NoLinkMic
  private readonly cancelRequestController = new CustomDialogController({
    builder: PLVSAConfirmDialog({
      title: $r('app.string.plvsa_linkmic_guest_cancel_request_text'),
      hasContent: false,
      onClickConfirm: (controller) => {
        this.sdk.linkmicManager.leaveLinkMic()
        controller?.close()
      }
    }),
    customStyle: true
  })
  private readonly leaveLinkMicController = new CustomDialogController({
    builder: PLVSAConfirmDialog({
      title: $r('app.string.plvsa_linkmic_guest_leave_linkmic_text'),
      hasContent: false,
      onClickConfirm: (controller) => {
        this.sdk.linkmicManager.leaveLinkMic()
        controller?.close()
      }
    }),
    customStyle: true
  })
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    const isChannelGuestAutoLinkMic = this.sdk.channelData.streamerData?.colinMicType === "auto"
    this.isVisible = !isChannelGuestAutoLinkMic
    this.sdk.linkmicManager.linkmicState.observe(it => this.linkmicState = it)
      .pushTo(this.observers)
  }

  build() {
    if (this.isVisible) {
      Image(this.linkmicButtonIcon())
        .width(36)
        .height(36)
        .onClick(() => {
          this.onClickLinkMicButton()
        })
    }
  }

  private linkmicButtonIcon(): Resource {
    switch (this.linkmicState) {
      case PLVLinkMicState.NoLinkMic:
      case PLVLinkMicState.Inviting:
      default:
        return $r('app.media.plvsa_linkmic_button_to_open')
      case PLVLinkMicState.Requesting:
      case PLVLinkMicState.WaitingResponse:
        return $r('app.media.plvsa_linkmic_waiting_response_anim')
      case PLVLinkMicState.Joined:
        return $r('app.media.plvsa_linkmic_button_to_close')
    }
  }

  private onClickLinkMicButton() {
    if (this.linkmicState === PLVLinkMicState.NoLinkMic) {
      this.sdk.linkmicManager.requestLinkMic()
    } else if (this.linkmicState === PLVLinkMicState.Requesting) {
      this.cancelRequestController.open()
    } else if (this.linkmicState === PLVLinkMicState.Joined) {
      this.leaveLinkMicController.open()
    }
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
    this.observers = []
  }
}