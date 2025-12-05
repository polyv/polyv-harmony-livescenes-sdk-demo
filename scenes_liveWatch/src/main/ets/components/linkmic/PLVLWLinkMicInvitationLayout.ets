import {
  PLVCommonConstants,
  PLVLinkMicMode,
  PLVLinkMicState,
  PLVLinkMicVideoRenderParam,
  PLVLinkMicViewer,
  PLVLiveSceneSDK,
  PLVScheduledTask,
  PLVToastUtils
} from '@polyvharmony/live-scenes-sdk';
import {
  extendNumber,
  lateInit,
  millis,
  MutableObserver,
  requirePermissions,
  seconds,
  watchStates
} from '@polyvharmony/media-player-sdk';
import { Permissions } from '@kit.AbilityKit';
import { media } from '@kit.MediaKit';
import { audio } from '@kit.AudioKit';
import { PLVLWLayoutDataBus } from '../../common/PLVLWLayoutDataBus';

@Component
export struct PLVLWLinkMicInvitationLayout {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @Consume('layoutDataBus') layoutDataBus: PLVLWLayoutDataBus
  @State isPortrait: boolean = true
  @State isVisible: boolean = false
  @State linkmicMode: PLVLinkMicMode = PLVLinkMicMode.VIDEO
  @State isCameraEnable: boolean = false
  @State isMicrophoneEnable: boolean = false
  @State acceptInvitationTimeLeft: number = 0
  @State localViewer: PLVLinkMicViewer | undefined = undefined
  private taskUpdateTimeLeft: PLVScheduledTask | undefined = undefined
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    watchStates(() => {
      this.isPortrait = this.layoutDataBus.isPortrait.value ?? true
    }).pushTo(this.observers)
    watchStates(() => {
      const linkmicState = this.sdk.linkmicManager.linkmicState.value
      const sdkSupportLinkMic = this.sdk.linkmicManager.sdkSupportChannelLinkMic.value ?? false
      const isVisible = linkmicState === PLVLinkMicState.Inviting && sdkSupportLinkMic
      this.isVisible = isVisible
      if (isVisible) {
        this.startTimeLeftCountDown()
        this.sdk.linkmicManager.enableCameraMicrophoneToLastState()
      } else {
        this.stopTimeLeftCountDown()
      }
    }).pushTo(this.observers)
    watchStates(() => {
      const localViewer = this.sdk.linkmicManager.localLinkMicViewer.value
      this.localViewer = localViewer
      this.isCameraEnable = localViewer?.isVideoEnable.value ?? false
      this.isMicrophoneEnable = localViewer?.isAudioEnable.value ?? false
    }).pushTo(this.observers)
    this.sdk.linkmicManager.channelLinkMicMode.observe((mode) => this.linkmicMode = mode)
      .pushTo(this.observers)
  }

  build() {
    if (this.isVisible) {
      RelativeContainer() {
        // 连麦邀请铃声
        PLVLWLinkMicInvitationSound()

        Column() {
          Text(this.linkmicMode === PLVLinkMicMode.VIDEO ? $r('app.string.plvlw_linkmic_invitation_title_video') : $r('app.string.plvlw_linkmic_invitation_title_audio'))
            .id('plvlw_linkmic_invitation_title_tv')
            .fontColor('#CC000000')
            .fontSize(16)
            .fontWeight(500)
            .padding({
              top: 18,
              bottom: 18
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
                this.sdk.linkmicManager.setupVideoRender(param)
              }).onDestroy(() => {
                const param = new PLVLinkMicVideoRenderParam(
                  this.localViewer!.linkmicId,
                  this.localViewer!.xcomponentId
                )
                this.sdk.linkmicManager.removeVideoRender(param)
              })
            }

            if (this.linkmicMode === PLVLinkMicMode.VIDEO && !this.isCameraEnable) {
              // 未开启摄像头提示
              Column() {
                Image($r('app.media.plvlw_linkmic_invitation_camera_closed_icon'))
                  .width(30)
                  .height(30)

                Text($r('app.string.plvlw_linkmic_invitation_camera_closed_text'))
                  .fontColor('#66000000')
                  .fontSize(12)
                  .margin({
                    top: 5
                  })
              }
              .width('100%')
              .height('100%')
              .backgroundColor('#0A000000')
              .alignItems(HorizontalAlign.Center)
              .justifyContent(FlexAlign.Center)
            }

            if (this.linkmicMode === PLVLinkMicMode.AUDIO) {
              // 音频连麦提示
              Stack() {
                Image($r('app.media.plvlw_linkmic_invitation_only_audio_hint_icon'))
                  .width(120)
              }
              .width('100%')
              .height('100%')
              .backgroundColor('#E1EEFF')
            }
          }
          .id('plvlw_linkmic_invitation_preview_container')
          .width('100%')
          .aspectRatio(16 / 9)
          .borderRadius(8)
          .clip(true)
          .margin({
            left: 32,
            right: 32
          })

          Column() {
            if (this.linkmicMode === PLVLinkMicMode.VIDEO) {
              // 摄像头开关
              Row() {
                Text($r('app.string.plvlw_linkmic_invitation_camera'))
                  .fontColor('#CC000000')
                  .fontSize(16)
                Blank()
                Toggle({
                  type: ToggleType.Switch,
                  isOn: this.isCameraEnable
                })
                  .width(38)
                  .height(24)
                  .selectedColor('#3F76FC')
                  .switchPointColor('#FFFFFF')
                  .onChange((isEnable) => {
                    const realCameraEnable = this.isCameraEnable
                    this.isCameraEnable = isEnable
                    this.isCameraEnable = realCameraEnable
                    if (isEnable) {
                      this.requirePermissionsWhenActive(
                        ['ohos.permission.CAMERA'],
                        () => {
                          this.enableCamera(true)
                        }
                      )
                    } else {
                      this.enableCamera(false)
                    }
                  })
              }
              .width('100%')
              .padding({
                top: this.isPortrait ? 16 : 8,
                bottom: this.isPortrait ? 16 : 8,
                left: 20,
                right: 20
              })

              Divider()
                .width('100%')
                .height(1)
                .color('#F5F5F5')
                .margin({
                  left: 20,
                  right: 20
                })
            }

            // 麦克风开关
            Row() {
              Text($r('app.string.plvlw_linkmic_invitation_microphone'))
                .fontColor('#CC000000')
                .fontSize(16)
              Blank()
              Toggle({
                type: ToggleType.Switch,
                isOn: this.isMicrophoneEnable
              })
                .width(38)
                .height(24)
                .selectedColor('#3F76FC')
                .switchPointColor('#FFFFFF')
                .onChange((isEnable) => {
                  const realMicrophoneEnable = this.isMicrophoneEnable
                  this.isMicrophoneEnable = isEnable
                  this.isMicrophoneEnable = realMicrophoneEnable
                  if (isEnable) {
                    this.requirePermissionsWhenActive(
                      ['ohos.permission.MICROPHONE'],
                      () => {
                        this.enableMicrophone(true)
                      }
                    )
                  } else {
                    this.enableMicrophone(false)
                  }
                })
            }
            .width('100%')
            .padding({
              top: this.isPortrait ? 16 : 8,
              bottom: this.isPortrait ? 16 : 8,
              left: 20,
              right: 20
            })
          }
          .id('plvlw_linkmic_invitation_switch_layout')
          .width('calc(100% - 64vp)')
          .borderRadius(8)
          .backgroundColor('#FFFFFF')
          .margin({
            top: 15
          })

          Row() {
            // 拒绝邀请连麦按钮
            Text($r('app.string.plvlw_linkmic_invitation_refuse_text', this.acceptInvitationTimeLeft.toString()))
              .height(44)
              .layoutWeight(5)
              .fontSize(16)
              .fontColor('#CC000000')
              .borderRadius(1000)
              .borderColor('#1A000000')
              .borderWidth(1)
              .textAlign(TextAlign.Center)
              .onClick(() => {
                this.sdk.linkmicManager.refuseLinkMicInvitation()
              })

            Blank()
              .layoutWeight(1)

            // 接受邀请连麦按钮
            Text($r('app.string.plvlw_linkmic_invitation_accept_text'))
              .height(44)
              .layoutWeight(5)
              .fontSize(16)
              .fontColor('#FFFFFF')
              .borderRadius(1000)
              .backgroundColor('#3F76FC')
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
          .id('plvlw_linkmic_invitation_answer_layout')
          .width('100%')
          .padding({
            left: 32,
            right: 32
          })
          .margin({
            top: 20,
            bottom: 34
          })
        }
        .id('plvlw_linkmic_invitation_layout')
        .width(this.isPortrait ? '100%' : 300)
        .height(this.isPortrait ? undefined : '100%')
        .alignRules({
          bottom: this.isPortrait ? { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Bottom } : undefined,
          end: this.isPortrait ? undefined : { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.End }
        })
        .backgroundColor('#F7F8FA')
        .borderRadius({
          topLeft: 16,
          topRight: this.isPortrait ? 16 : 0,
          bottomLeft: this.isPortrait ? 0 : 16
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

  private enableCamera(open: boolean) {
    this.sdk.linkmicManager.enableCamera(open)
    PLVToastUtils.shortShow(open ? $r('app.string.plvlw_linkmic_toast_camera_open') : $r('app.string.plvlw_linkmic_toast_camera_close'))
  }

  private enableMicrophone(open: boolean) {
    this.sdk.linkmicManager.enableMicrophone(open)
    PLVToastUtils.shortShow(open ? $r('app.string.plvlw_linkmic_toast_microphone_open') : $r('app.string.plvlw_linkmic_toast_microphone_close'))
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
struct PLVLWLinkMicInvitationSound {
  private readonly soundFileName = "plvlw_linkmic_invitation_bgm.mp3"
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