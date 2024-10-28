import {
  PLVLinkMicMode,
  PLVLinkMicState,
  PLVLinkMicVideoRenderParam,
  PLVLinkMicViewer,
  PLVLiveSceneSDK,
  PLVScheduledTask
} from '@polyvharmony/live-scenes-sdk';
import {
  DerivedState,
  extendNumber,
  lateInit,
  millis,
  MutableObserver,
  requirePermissions,
  seconds
} from '@polyvharmony/media-player-sdk';
import { Permissions } from '@kit.AbilityKit';
import { media } from '@kit.MediaKit';
import { audio } from '@kit.AudioKit';

@Component
export struct PLVLILinkMicInvitationLayout {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @State isVisible: boolean = false
  @State linkmicMode: PLVLinkMicMode = PLVLinkMicMode.VIDEO
  @State isCameraEnable: boolean = false
  @State isMicrophoneEnable: boolean = false
  @State acceptInvitationTimeLeft: number = 0
  @State localViewer: PLVLinkMicViewer | undefined = undefined
  private taskUpdateTimeLeft: PLVScheduledTask | undefined = undefined
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    const stateVisible = new DerivedState(() => {
      const linkmicState = this.sdk.linkmicManager.linkmicState.value
      const sdkSupportLinkMic = this.sdk.linkmicManager.sdkSupportChannelLinkMic.value ?? false
      return linkmicState === PLVLinkMicState.Inviting && sdkSupportLinkMic
    })
    stateVisible.observe((isVisible) => {
      this.isVisible = isVisible
      if (isVisible) {
        this.startTimeLeftCountDown()
        this.sdk.linkmicManager.enableCameraMicrophoneToLastState()
      } else {
        this.stopTimeLeftCountDown()
      }
    }).pushTo(this.observers)
    this.sdk.linkmicManager.localLinkMicViewer.observe((localViewer) => this.localViewer = localViewer)
      .pushTo(this.observers)
    this.sdk.linkmicManager.channelLinkMicMode.observe((mode) => this.linkmicMode = mode)
      .pushTo(this.observers)
    const stateOpenCamera = new DerivedState(() => this.sdk.linkmicManager.localLinkMicViewer.value?.isVideoEnable.value ?? false)
    stateOpenCamera.observe((openCamera) => this.isCameraEnable = openCamera).pushTo(this.observers)
    const stateOpenMicrophone = new DerivedState(() => this.sdk.linkmicManager.localLinkMicViewer.value?.isAudioEnable.value ?? false)
    stateOpenMicrophone.observe((openMicrophone) => this.isMicrophoneEnable = openMicrophone).pushTo(this.observers)
  }

  build() {
    if (this.isVisible) {
      Column() {
        // 连麦邀请铃声
        PLVLILinkMicInvitationSound()
        Blank()
        Column() {
          Text(this.linkmicMode === PLVLinkMicMode.VIDEO ? $r('app.string.plvli_linkmic_invitation_title_video') : $r('app.string.plvli_linkmic_invitation_title_audio'))
            .id('plvli_linkmic_invitation_title_tv')
            .fontColor('#FFFFFF')
            .fontSize(16)
            .padding({
              top: 16,
              bottom: 16
            })

          Stack() {
            if (this.linkmicMode === PLVLinkMicMode.VIDEO && this.isCameraEnable && this.localViewer !== undefined) {
              // 摄像头预览
              XComponent({
                id: this.localViewer.xcomponentId,
                type: 'surface',
                libraryname: this.localViewer.xcomponentLibraryName
              }).onLoad(() => {
                const param = new PLVLinkMicVideoRenderParam(
                  this.localViewer!.linkmicId,
                  this.localViewer!.xcomponentId
                )
                this.sdk.linkmicManager.setVideoRender(param)
              }).onDestroy(() => {
                const param = new PLVLinkMicVideoRenderParam(
                  this.localViewer!.linkmicId,
                  null
                )
                this.sdk.linkmicManager.setVideoRender(param)
              })
            }

            if (this.linkmicMode === PLVLinkMicMode.VIDEO && !this.isCameraEnable) {
              // 未开启摄像头提示
              Column() {
                Image($r('app.media.plvli_linkmic_invitation_camera_closed_icon'))
                  .width(80)
                  .height(80)

                Text($r('app.string.plvli_linkmic_invitation_camera_closed_text'))
                  .fontColor('#70FFFFFF')
                  .fontSize(14)
              }
              .width('100%')
              .height('100%')
              .backgroundColor('#353535')
              .alignItems(HorizontalAlign.Center)
              .justifyContent(FlexAlign.Center)
            }

            if (this.linkmicMode === PLVLinkMicMode.AUDIO) {
              // 音频连麦提示
              Stack() {
                Image($r('app.media.plvli_linkmic_invitation_only_audio_hint_icon'))
                  .width(120)
              }
              .width('100%')
              .height('100%')
              .backgroundColor('#E1EEFF')
            }
          }
          .id('plvli_linkmic_invitation_preview_container')
          .width('100%')
          .aspectRatio(16 / 9)
          .margin({
            left: 24,
            right: 24
          })

          Column() {
            if (this.linkmicMode === PLVLinkMicMode.VIDEO) {
              // 摄像头开关
              Row() {
                Image($r('app.media.plvli_linkmic_invitation_camera_icon'))
                  .width(24)
                  .height(24)
                Text($r('app.string.plvli_linkmic_invitation_camera'))
                  .fontColor('#FFFFFF')
                  .fontSize(16)
                  .margin({
                    left: 13
                  })
                Blank()
                Toggle({
                  type: ToggleType.Switch,
                  isOn: this.isCameraEnable
                })
                  .width(28)
                  .height(16)
                  .selectedColor('#FFA611')
                  .switchPointColor('#FFFFFF')
                  .onChange((isEnable) => {
                    const realCameraEnable = this.isCameraEnable
                    this.isCameraEnable = isEnable
                    this.isCameraEnable = realCameraEnable
                    if (isEnable) {
                      this.requirePermissionsWhenActive(
                        ['ohos.permission.CAMERA'],
                        () => {
                          this.sdk.linkmicManager.enableCamera(true)
                        }
                      )
                    } else {
                      this.sdk.linkmicManager.enableCamera(false)
                    }
                  })
              }
              .width('100%')
              .padding({
                top: 16,
                bottom: 16,
                left: 24,
                right: 24
              })
            }

            // 麦克风开关
            Row() {
              Image($r('app.media.plvli_linkmic_invitation_microphone_icon'))
                .width(24)
                .height(24)
              Text($r('app.string.plvli_linkmic_invitation_microphone'))
                .fontColor('#FFFFFF')
                .fontSize(16)
                .margin({
                  left: 13
                })
              Blank()
              Toggle({
                type: ToggleType.Switch,
                isOn: this.isMicrophoneEnable
              })
                .width(28)
                .height(16)
                .selectedColor('#FFA611')
                .switchPointColor('#FFFFFF')
                .onChange((isEnable) => {
                  const realMicrophoneEnable = this.isMicrophoneEnable
                  this.isMicrophoneEnable = isEnable
                  this.isMicrophoneEnable = realMicrophoneEnable
                  if (isEnable) {
                    this.requirePermissionsWhenActive(
                      ['ohos.permission.MICROPHONE'],
                      () => {
                        this.sdk.linkmicManager.enableMicrophone(true)
                      }
                    )
                  } else {
                    this.sdk.linkmicManager.enableMicrophone(false)
                  }
                })
            }
            .width('100%')
            .padding({
              top: 16,
              bottom: 16,
              left: 24,
              right: 24
            })
          }
          .id('plvli_linkmic_invitation_switch_layout')
          .width('100%')

          // 隐私提示
          Row() {
            Image($r('app.media.plvli_linkmic_invitation_privacy_notify_icon'))
              .width(12)
              .height(12)
            Text($r('app.string.plvli_linkmic_invitation_privacy_notify'))
              .fontColor('#99FFFFFF')
              .fontSize(12)
              .margin({
                left: 8
              })
          }
          .id('plvli_linkmic_invitation_privacy_notify_layout')
          .width('100%')
          .padding({
            top: 8,
            bottom: 8,
            left: 24,
            right: 24
          })

          Row() {
            // 拒绝邀请连麦按钮
            Text($r('app.string.plvli_linkmic_invitation_refuse_text', this.acceptInvitationTimeLeft.toString()))
              .height(40)
              .layoutWeight(5)
              .fontSize(14)
              .fontColor('#FFA611')
              .borderRadius(1000)
              .borderColor('#FFA611')
              .borderWidth(1)
              .textAlign(TextAlign.Center)
              .onClick(() => {
                this.sdk.linkmicManager.refuseLinkMicInvitation()
              })

            Blank()
              .layoutWeight(1)

            // 接受邀请连麦按钮
            Text($r('app.string.plvli_linkmic_invitation_accept_text'))
              .height(40)
              .layoutWeight(5)
              .fontSize(14)
              .fontColor('#FFFFFF')
              .borderRadius(1000)
              .backgroundColor('#FFA611')
              .textAlign(TextAlign.Center)
              .onClick(() => {
                this.requirePermissionsWhenActive(
                  ['ohos.permission.CAMERA', 'ohos.permission.MICROPHONE'],
                  () => {
                    this.sdk.linkmicManager.acceptLinkMicInvitation()
                  }
                )
              })
          }
          .id('plvli_linkmic_invitation_answer_layout')
          .width('100%')
          .padding({
            top: 16,
            bottom: 34,
            left: 24,
            right: 24
          })

        }
        .id('plvli_linkmic_invitation_layout')
        .width('100%')
        .backgroundColor('#262523')
        .borderRadius({
          topLeft: 6,
          topRight: 6
        })
      }
      .width('100%')
      .height('100%')
    }
  }

  private async requirePermissionsWhenActive(permissions: Permissions[], onGranted: () => void) {
    const result = await requirePermissions(...permissions)
    if (result.granted.length === permissions.length && this.isVisible) {
      onGranted()
    }
  }

  private startTimeLeftCountDown() {
    this.stopTimeLeftCountDown()
    this.taskUpdateTimeLeft = new PLVScheduledTask(
      () => {
        const now = Date.now()
        const expire = this.sdk.linkmicManager.invitationExpireTimestamp.value ?? now
        const timeLeft = millis(expire - now).toSeconds(Math.floor)
        this.acceptInvitationTimeLeft = extendNumber(timeLeft).coerceAtLeast_ext(0)
      },
      0,
      seconds(1).toMillis()
    )
    this.taskUpdateTimeLeft.start()
  }

  private stopTimeLeftCountDown() {
    this.taskUpdateTimeLeft?.cancel()
    this.taskUpdateTimeLeft = undefined
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
    this.observers = []
  }
}

@Component
struct PLVLILinkMicInvitationSound {
  private readonly soundFileName = "plvli_linkmic_invitation_bgm.mp3"
  private readonly resourceManager = getContext().resourceManager
  private soundPool: media.SoundPool | undefined = undefined
  private soundId: number | undefined = undefined
  private streamId: number | undefined = undefined

  async aboutToAppear(): Promise<void> {
    const rawFd = await this.resourceManager.getRawFd(this.soundFileName)
    const audioRenderInfo: audio.AudioRendererInfo = {
      usage: audio.StreamUsage.STREAM_USAGE_MUSIC,
      rendererFlags: 0
    }
    this.soundPool = await media.createSoundPool(1, audioRenderInfo)
    this.soundPool.load(rawFd.fd, rawFd.offset, rawFd.length)
    this.soundPool.on('loadComplete', async (soundId) => {
      this.soundId = soundId
      const playParam: media.PlayParameters = {
        loop: -1,
        leftVolume: 1,
        rightVolume: 1
      }
      this.streamId = await this.soundPool?.play(this.soundId, playParam)
    })
  }

  build() {
  }

  async aboutToDisappear(): Promise<void> {
    this.soundPool?.off('loadComplete')
    if (this.streamId !== undefined) {
      this.soundPool?.stop(this.streamId)
      this.streamId = undefined
    }
    if (this.soundId !== undefined) {
      this.soundPool?.unload(this.soundId)
      this.soundId = undefined
    }
    await this.soundPool?.release()
    await this.resourceManager.closeRawFd(this.soundFileName)
  }
}