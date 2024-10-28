import { PLVLinkMicMode, PLVLinkMicState, PLVLiveSceneSDK } from '@polyvharmony/live-scenes-sdk'
import { DerivedState, lateInit, MutableObserver, RequirePermissions, seconds } from '@polyvharmony/media-player-sdk'

const CONTROL_BAR_MAX_WIDTH = 202

@Component
export struct PLVLILinkMicControlBarPort {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @State linkmicState: PLVLinkMicState = PLVLinkMicState.NoLinkMic
  @State joinLinkMicQueueOrder: number = -1
  @State channelLinkMicMode: PLVLinkMicMode = PLVLinkMicMode.VIDEO
  @State isOpenCamera: boolean = false
  @State isOpenMicrophone: boolean = false
  @State controlBarCollapse: boolean = false
  @State controlBarTranslationX: number = CONTROL_BAR_MAX_WIDTH
  @State controlBarTranslationY: number = 0
  private baseTranslationY: number = this.controlBarTranslationY
  private isVisible: boolean = false
  private collapseControlBarTimestamp: number = 0
  private isDragging: boolean = false
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    this.sdk.linkmicManager.linkmicState.observe((linkmicState) => {
      this.linkmicState = linkmicState
      this.expandControlBar()
    })
      .pushTo(this.observers)
    this.sdk.linkmicManager.joinLinkMicWaitingQueueOrder.observe((order) => {
      this.joinLinkMicQueueOrder = order
    })
      .pushTo(this.observers)
    this.sdk.linkmicManager.channelLinkMicMode.observe((mode) => {
      this.channelLinkMicMode = mode
      this.updateControlBarWidthAnim()
    })
      .pushTo(this.observers)
    const stateVisible = new DerivedState(() => {
      const sdkSupport = this.sdk.linkmicManager.sdkSupportChannelLinkMic.value ?? false
      const allowLinkMic = this.sdk.linkmicManager.channelAllowLinkMic.value ?? false
      const allowRequestLinkMic = this.sdk.linkmicManager.channelAllowRequestHandsUpLinkMic.value ?? false
      const isJoinLinkMic = this.sdk.linkmicManager.linkmicState.value === PLVLinkMicState.Joined
      return (sdkSupport && allowLinkMic && allowRequestLinkMic) || isJoinLinkMic
    })
    stateVisible.observe((isVisible) => {
      this.isVisible = isVisible
      this.expandControlBar()
    }).pushTo(this.observers)
    const stateOpenCamera = new DerivedState(() => this.sdk.linkmicManager.localLinkMicViewer.value?.isVideoEnable.value ?? false)
    stateOpenCamera.observe((openCamera) => this.isOpenCamera = openCamera).pushTo(this.observers)
    const stateOpenMicrophone = new DerivedState(() => this.sdk.linkmicManager.localLinkMicViewer.value?.isAudioEnable.value ?? false)
    stateOpenMicrophone.observe((openMicrophone) => this.isOpenMicrophone = openMicrophone).pushTo(this.observers)
  }

  build() {
    Row() {
      // 连麦控制按钮
      Image(this.ringButtonImageForState())
        .width(32)
        .height(32)
        .margin({
          left: 8,
          right: 4
        })
        .onClick(() => this.onClickRingButton())

      if ([PLVLinkMicState.NoLinkMic, PLVLinkMicState.Inviting, PLVLinkMicState.WaitingResponse].includes(this.linkmicState)) {
        // 提示文本
        Text(this.requestTipsForState())
          .fontColor('#FFFFFF')
          .fontSize(16)
          .margin({
            left: 4,
            right: 4
          })
      }

      if (this.linkmicState === PLVLinkMicState.Requesting) {
        Column() {
          // 提示文本
          Text(this.requestTipsForState())
            .fontColor('#FFFFFF')
            .fontSize(16)
          if (this.joinLinkMicQueueOrder >= 0) {
            // 排队位置文本
            Text(this.requestQueueOrderText())
              .fontColor('#99FFFFFF')
              .fontSize(12)
          }
        }
        .margin({
          left: 4,
          right: 4
        })
        .alignItems(HorizontalAlign.Start)
      }

      if (this.linkmicState === PLVLinkMicState.Joined) {
        if (this.channelLinkMicMode === PLVLinkMicMode.VIDEO) {
          // 摄像头开关
          Image(this.isOpenCamera ? $r("app.media.plvli_linkmic_camera_icon_open") : $r("app.media.plvli_linkmic_camera_icon_close"))
            .width(32)
            .height(32)
            .margin({
              left: 4,
              right: 4
            })
            .onClick(() => this.onClickEnableCameraButton())
          // 切换前后摄像头
          Image(this.isOpenCamera ? $r("app.media.plvli_linkmic_camera_switch_facing_enabled") : $r("app.media.plvli_linkmic_camera_switch_facing_disabled"))
            .width(32)
            .height(32)
            .margin({
              left: 4,
              right: 4
            })
            .onClick(() => this.onClickSwitchCameraButton())
        }
        // 麦克风开关
        Image(this.isOpenMicrophone ? $r("app.media.plvli_linkmic_microphone_icon_open") : $r("app.media.plvli_linkmic_microphone_icon_close"))
          .width(32)
          .height(32)
          .margin({
            left: 4,
            right: 4
          })
          .onClick(() => this.onClickEnableMicrophoneButton())
        // 折叠控制栏
        Image($r("app.media.plvli_linkmic_control_bar_collapse_icon"))
          .width(18)
          .height(18)
          .margin({
            left: 8,
            right: 8
          })
          .onClick(() => this.onClickCollapse())
      }

    }
    .width(CONTROL_BAR_MAX_WIDTH)
    .height(48)
    .backgroundColor('#3E3E4E')
    .borderRadius({
      topLeft: 24,
      bottomLeft: 24
    })
    .translate({
      x: this.controlBarTranslationX,
      y: this.controlBarTranslationY
    })
    .gesture(
      PanGesture({
        direction: PanDirection.Vertical
      }).onActionStart(() => {
        this.isDragging = true
        this.baseTranslationY = this.controlBarTranslationY
      }).onActionUpdate((event) => {
        this.controlBarTranslationY = this.baseTranslationY + event.offsetY
      }).onActionEnd(() => {
        this.isDragging = false
        this.delayCollapseControlBar(seconds(5).toMillis())
      }).onActionCancel(() => {
        this.isDragging = false
        this.delayCollapseControlBar(seconds(5).toMillis())
      })
    )
    .alignItems(VerticalAlign.Center)
  }

  private ringButtonImageForState(): Resource {
    switch (this.linkmicState) {
      case PLVLinkMicState.NoLinkMic:
      case PLVLinkMicState.Inviting:
      case PLVLinkMicState.WaitingResponse:
      default:
        return $r("app.media.plvli_linkmic_ring_btn_to_request_icon")
      case PLVLinkMicState.Requesting:
        return $r("app.media.plvli_linkmic_ring_btn_to_close_icon")
      case PLVLinkMicState.Joined:
        if (this.controlBarCollapse) {
          return $r("app.media.plvli_linkmic_ring_btn_setting_icon")
        } else {
          return $r("app.media.plvli_linkmic_ring_btn_to_close_icon")
        }
    }
  }

  private requestTipsForState(): Resource {
    switch (this.linkmicState) {
      case PLVLinkMicState.NoLinkMic:
      case PLVLinkMicState.Inviting:
      case PLVLinkMicState.WaitingResponse:
      default:
        if (this.channelLinkMicMode === PLVLinkMicMode.AUDIO) {
          return $r("app.string.plvli_linkmic_tip_request_join_audio")
        } else {
          return $r("app.string.plvli_linkmic_tip_request_join_video")
        }
      case PLVLinkMicState.Requesting:
        return $r("app.string.plvli_linkmic_tip_requesting")
    }
  }

  private requestQueueOrderText(): Resource {
    if (this.joinLinkMicQueueOrder < 50) {
      return $r("app.string.plvli_linkmic_tip_request_order", (this.joinLinkMicQueueOrder + 1).toString())
    } else {
      return $r("app.string.plvli_linkmic_tip_request_order", "50+")
    }
  }

  private updateControlBarWidthAnim() {
    let controlBarTargetWidth = CONTROL_BAR_MAX_WIDTH
    switch (this.linkmicState) {
      case PLVLinkMicState.NoLinkMic:
      case PLVLinkMicState.Inviting:
      case PLVLinkMicState.WaitingResponse:
      default:
        if (this.controlBarCollapse) {
          controlBarTargetWidth = 48
        } else {
          controlBarTargetWidth = 160
        }
        break;
      case PLVLinkMicState.Requesting:
        controlBarTargetWidth = 130;
        break;
      case PLVLinkMicState.Joined:
        if (this.controlBarCollapse) {
          controlBarTargetWidth = 48
        } else {
          if (this.channelLinkMicMode === PLVLinkMicMode.VIDEO) {
            controlBarTargetWidth = 202
          } else {
            controlBarTargetWidth = 122
          }
        }
        break;
    }
    if (!this.isVisible) {
      controlBarTargetWidth = 0
    }
    const translationX = CONTROL_BAR_MAX_WIDTH - controlBarTargetWidth

    this.getUIContext().animateTo(
      { curve: Curve.Smooth, duration: 300 },
      () => {
        this.controlBarTranslationX = translationX
      }
    )
  }

  private onClickRingButton() {
    switch (this.linkmicState) {
      case PLVLinkMicState.NoLinkMic:
      case PLVLinkMicState.Inviting:
      case PLVLinkMicState.WaitingResponse:
      default:
        this.requestJoinLinkMic();
        break;
      case PLVLinkMicState.Requesting:
        this.sdk.linkmicManager.leaveLinkMic();
        break;
      case PLVLinkMicState.Joined:
        if (this.controlBarCollapse) {
          this.expandControlBar();
        } else {
          this.sdk.linkmicManager.leaveLinkMic();
        }
        break;
    }
  }

  @RequirePermissions('ohos.permission.CAMERA', 'ohos.permission.MICROPHONE')
  private requestJoinLinkMic() {
    this.sdk.linkmicManager.requestLinkMic();
  }

  private onClickEnableCameraButton() {
    const toEnable = !this.isOpenCamera
    this.sdk.linkmicManager.enableCamera(toEnable)
  }

  private onClickSwitchCameraButton() {
    if (this.isOpenCamera) {
      this.sdk.linkmicManager.switchCamera()
    }
  }

  private onClickEnableMicrophoneButton() {
    const toEnable = !this.isOpenMicrophone
    this.sdk.linkmicManager.enableMicrophone(toEnable)
  }

  private onClickCollapse() {
    this.setControlBarCollapse(true)
  }

  private expandControlBar(autoCollapse: boolean = true) {
    this.setControlBarCollapse(false)
    if (autoCollapse) {
      this.delayCollapseControlBar(seconds(5).toMillis())
    }
  }

  private delayCollapseControlBar(delay: number) {
    this.collapseControlBarTimestamp = Date.now() + delay
    setTimeout(() => {
      if (this.isDragging) {
        return
      }
      if (Date.now() >= this.collapseControlBarTimestamp) {
        this.setControlBarCollapse(true)
      }
    }, delay)
  }

  private setControlBarCollapse(collapse: boolean) {
    this.controlBarCollapse = collapse
    this.updateControlBarWidthAnim()
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
    this.observers = []
  }
}