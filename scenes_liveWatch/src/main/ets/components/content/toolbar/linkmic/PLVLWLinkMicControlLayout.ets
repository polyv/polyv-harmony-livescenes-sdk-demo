import {
  PLVCommonConstants,
  PLVLinkMicMode,
  PLVLinkMicState,
  PLVLiveSceneSDK,
  PLVToastUtils
} from '@polyvharmony/live-scenes-sdk'
import { lateInit, MutableObserver, RequirePermissions, watchStates } from '@polyvharmony/media-player-sdk'
import { PLVLWConfirmDialog } from '../../../../common/widget/PLVLWConfirmDialog'

@Component
export struct PLVLWToolBarLinkMicControlIcon {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @Link isLinkMicIconVisible: boolean
  private readonly linkmicControlDialogController = new CustomDialogController({
    builder: PLVLWLinkMicControlLayout(),
    alignment: DialogAlignment.Bottom,
    customStyle: true
  })
  @State private linkmicState: PLVLinkMicState = PLVLinkMicState.NoLinkMic
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    watchStates(() => {
      const sdkSupport = this.sdk.linkmicManager.sdkSupportChannelLinkMic.value ?? false
      const allowLinkMic = this.sdk.linkmicManager.channelAllowLinkMic.value ?? false
      const allowRequestLinkMic = this.sdk.linkmicManager.channelAllowRequestHandsUpLinkMic.value ?? false
      const linkmicState = this.sdk.linkmicManager.linkmicState.value ?? PLVLinkMicState.NoLinkMic
      const isVisible = (sdkSupport && allowLinkMic && allowRequestLinkMic) || linkmicState === PLVLinkMicState.Joined
      this.isLinkMicIconVisible = isVisible
      this.linkmicState = linkmicState
    }).pushTo(this.observers)
    this.watchTeacherAcceptRequestLinkMic()
  }

  private watchTeacherAcceptRequestLinkMic() {
    let lastLinkMicState = PLVLinkMicState.NoLinkMic
    watchStates(() => {
      const newLinkMicState = this.sdk.linkmicManager.linkmicState.value ?? PLVLinkMicState.NoLinkMic
      if (lastLinkMicState === PLVLinkMicState.Requesting) {
        if (newLinkMicState === PLVLinkMicState.WaitingResponse || newLinkMicState === PLVLinkMicState.Joined) {
          this.linkmicControlDialogController.close()
          PLVToastUtils.shortShow($r('app.string.plvlw_linkmic_toast_accept_request'))
        }
      }
      lastLinkMicState = newLinkMicState
    }).pushTo(this.observers)
  }

  build() {
    Image(this.linkmicIcon())
      .backgroundColor('#33000000')
      .borderRadius(1000)
      .onClick(() => {
        this.linkmicControlDialogController.open()
      })
  }

  private linkmicIcon(): Resource {
    switch (this.linkmicState) {
      case PLVLinkMicState.NoLinkMic:
        return $r('app.media.plvlw_linkmic_control_normal')
      case PLVLinkMicState.Requesting:
      case PLVLinkMicState.Inviting:
      case PLVLinkMicState.WaitingResponse:
        return $r('app.media.plvlw_linkmic_control_connecting')
      case PLVLinkMicState.Joined:
        return $r('app.media.plvlw_linkmic_control_joined')
      default:
        return $r('app.media.plvlw_linkmic_control_normal')
    }
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
  }
}

@CustomDialog
struct PLVLWLinkMicControlLayout {
  dialog: CustomDialogController = lateInit()
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @State private linkmicState: PLVLinkMicState = PLVLinkMicState.NoLinkMic
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    watchStates(() => {
      this.linkmicState = this.sdk.linkmicManager.linkmicState.value ?? PLVLinkMicState.NoLinkMic
    }).pushTo(this.observers)
  }

  build() {
    Column() {
      if (this.linkmicState === PLVLinkMicState.NoLinkMic) {
        PLVLWLinkMicControlLayoutNoLinkMic({
          dialog: this.dialog
        })
      }
      if (this.linkmicState === PLVLinkMicState.Requesting) {
        PLVLWLinkMicControlLayoutRequesting({
          dialog: this.dialog
        })
      }
      if (this.linkmicState === PLVLinkMicState.Inviting) {
        PLVLWLinkMicControlLayoutNoLinkMic({
          dialog: this.dialog
        })
      }
      if (this.linkmicState === PLVLinkMicState.WaitingResponse) {
        PLVLWLinkMicControlLayoutWaitingResponse({
          dialog: this.dialog
        })
      }
      if (this.linkmicState === PLVLinkMicState.Joined) {
        PLVLWLinkMicControlLayoutJoined({
          dialog: this.dialog
        })
      }
    }
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
  }
}

@Component
struct PLVLWLinkMicControlLayoutNoLinkMic {
  dialog: CustomDialogController = lateInit()
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()

  build() {
    Column() {
      Text($r('app.string.plvlw_linkmic_tip_request_join'))
        .width(PLVCommonConstants.FULL_PERCENT)
        .textAlign(TextAlign.Center)
        .fontSize(16)
        .fontColor('#333333')
        .padding({
          top: 14,
          bottom: 14
        })
        .onClick(() => {
          const isAllowRequestHandsUpLinkMic = this.sdk.linkmicManager.channelAllowRequestHandsUpLinkMic.value ?? false
          if (isAllowRequestHandsUpLinkMic) {
            this.requestJoinLinkMic()
          }
        })
      Divider()
        .height(8)
        .color('#F7F8FA')
      Text($r('app.string.plvlw_confirm_dialog_cancel'))
        .width(PLVCommonConstants.FULL_PERCENT)
        .textAlign(TextAlign.Center)
        .fontSize(16)
        .fontColor('#333333')
        .padding({
          top: 14,
          bottom: 14
        })
        .onClick(() => {
          this.dialog.close()
        })
    }
    .width(PLVCommonConstants.FULL_PERCENT)
    .backgroundColor('#FFFFFF')
    .borderRadius({
      topLeft: 16,
      topRight: 16
    })
  }

  @RequirePermissions('ohos.permission.CAMERA','ohos.permission.MICROPHONE')
  private requestJoinLinkMic() {
    this.sdk.linkmicManager.requestLinkMic();
  }
}

@Component
struct PLVLWLinkMicControlLayoutRequesting {
  dialog: CustomDialogController = lateInit()
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()

  build() {
    Column() {
      Text($r('app.string.plvlw_linkmic_tip_requesting'))
        .fontSize(16)
        .fontWeight(500)
        .fontColor('#CC000000')
        .margin({
          top: 15
        })
      Text($r('app.string.plvlw_linkmic_tip_requesting_2'))
        .fontSize(14)
        .fontColor('#66000000')
        .margin({
          top: 35
        })
        .margin({
          top: 35,
          left: 32,
          right: 32
        })
      Row() {
        Image(this.sdk.channelData.viewerAvatar ?? $r('app.media.plvlw_chatroom_ic_viewer'))
          .width(46)
          .height(46)
          .borderRadius(1000)
        Image($r('app.media.plvlw_linkmic_requesting_anim'))
          .width(21)
          .height(3)
          .objectFit(ImageFit.Contain)
          .margin({
            left: 13,
            right: 13
          })
        RelativeContainer() {
          Image(this.sdk.channelData.liveDetail?.coverImage)
            .width(46)
            .height(46)
            .borderRadius(1000)
          Text($r('app.string.plvlw_player_lecturer'))
            .fontSize(9)
            .fontColor('#FFFFFF')
            .padding({
              left: 5,
              right: 5
            })
            .linearGradient({
              angle: 90,
              colors: [
                ['#2987FF', 0],
                ['#57B7FF', 1]
              ]
            })
            .borderRadius(8)
            .alignRules({
              bottom: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Bottom },
              middle: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Center }
            })
            .margin({
              bottom: -4
            })
        }
        .width(46)
        .height(46)
      }
      .margin({
        top: 20
      })

      Text($r('app.string.plvlw_linkmic_request_cancel'))
        .width(200)
        .height(44)
        .textAlign(TextAlign.Center)
        .fontSize(16)
        .fontColor('#FFFFFF')
        .borderRadius(22)
        .backgroundColor('#3F76FC')
        .margin({
          top: 34,
          bottom: 34
        })
        .onClick(() => {
          this.dialog.close()
          this.sdk.linkmicManager.leaveLinkMic()
        })
    }
    .width(PLVCommonConstants.FULL_PERCENT)
    .backgroundColor('#FFFFFF')
    .borderRadius({
      topLeft: 16,
      topRight: 16
    })
  }
}

@Component
struct PLVLWLinkMicControlLayoutWaitingResponse {
  dialog: CustomDialogController = lateInit()

  aboutToAppear(): void {
    this.dialog.close()
  }

  build() {

  }
}

@Component
struct PLVLWLinkMicControlLayoutJoined {
  dialog: CustomDialogController = lateInit()
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  private readonly hangOffLinkMicDialog = new CustomDialogController({
    builder: PLVLWConfirmDialog({
      hasTitle: false,
      content: $r('app.string.plvlw_linkmic_hang_off_dialog_content'),
      confirmText: $r('app.string.plvlw_linkmic_hang_off_dialog_confirm'),
      onClickConfirm: (dialog) => {
        this.sdk.linkmicManager.leaveLinkMic()
        dialog?.close()
      }
    }),
    autoCancel: false,
    customStyle: true
  })
  @State private showCameraControl: boolean = false
  @State private isCameraEnable: boolean = false
  @State private isMicrophoneEnable: boolean = false
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    watchStates(() => {
      const localViewer = this.sdk.linkmicManager.localLinkMicViewer.value
      this.isCameraEnable = localViewer?.isVideoEnable.value ?? false
      this.isMicrophoneEnable = localViewer?.isAudioEnable.value ?? false
    }).pushTo(this.observers)
    watchStates(() => {
      this.showCameraControl = this.sdk.linkmicManager.channelLinkMicMode.value === PLVLinkMicMode.VIDEO
    }).pushTo(this.observers)
  }

  build() {
    Row() {
      if (this.showCameraControl) {
        Column() {
          Image(this.isCameraEnable ? $r('app.media.plvlw_linkmic_camera_state_open') : $r('app.media.plvlw_linkmic_camera_state_close'))
            .width(30)
            .height(30)
          Text(this.isCameraEnable ? $r('app.string.plvlw_linkmic_camera_to_close') : $r('app.string.plvlw_linkmic_camera_to_open'))
            .fontSize(12)
            .fontColor('#99000000')
            .margin({
              top: 5
            })
        }
        .width(94)
        .height(76)
        .onClick(() => {
          this.enableCamera(!this.isCameraEnable)
        })
      }

      Column() {
        Image(this.isMicrophoneEnable ? $r('app.media.plvlw_linkmic_microphone_state_open') : $r('app.media.plvlw_linkmic_microphone_state_close'))
          .width(30)
          .height(30)
        Text(this.isMicrophoneEnable ? $r('app.string.plvlw_linkmic_microphone_to_close') : $r('app.string.plvlw_linkmic_microphone_to_open'))
          .fontSize(12)
          .fontColor('#99000000')
          .margin({
            top: 5
          })
      }
      .width(94)
      .height(76)
      .onClick(() => {
        this.enableMicrophone(!this.isMicrophoneEnable)
      })

      Column() {
        Image($r('app.media.plvlw_linkmic_hang_off_icon'))
          .width(30)
          .height(30)
        Text($r('app.string.plvlw_linkmic_control_leave'))
          .fontSize(12)
          .fontColor('#99000000')
          .margin({
            top: 5
          })
      }
      .width(94)
      .height(76)
      .onClick(() => {
        this.hangOffLinkMicDialog.open()
        this.dialog?.close()
      })
    }
    .width(PLVCommonConstants.FULL_PERCENT)
    .borderRadius({
      topLeft: 16,
      topRight: 16
    })
    .padding({
      top: 12,
      bottom: 34
    })
    .backgroundColor('#FFFFFF')
  }

  private enableCamera(open: boolean) {
    this.sdk.linkmicManager.enableCamera(open)
    PLVToastUtils.shortShow(open ? $r('app.string.plvlw_linkmic_toast_camera_open') : $r('app.string.plvlw_linkmic_toast_camera_close'))
  }

  private enableMicrophone(open: boolean) {
    this.sdk.linkmicManager.enableMicrophone(open)
    PLVToastUtils.shortShow(open ? $r('app.string.plvlw_linkmic_toast_microphone_open') : $r('app.string.plvlw_linkmic_toast_microphone_close'))
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
  }
}