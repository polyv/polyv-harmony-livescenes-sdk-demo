import { PLVLinkMicState, PLVLiveSceneSDK, PLVScheduledTask } from '@polyvharmony/live-scenes-sdk';
import {
  DerivedState,
  extendNumber,
  lateInit,
  millis,
  MutableObserver,
  seconds
} from '@polyvharmony/media-player-sdk';
import { media } from '@kit.MediaKit';
import { audio } from '@kit.AudioKit';

@Component
export struct PLVSALinkMicInvitationLayout {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  private readonly invitationDialog = new CustomDialogController({
    builder: PLVSALinkMicInvitationDialog(),
    autoCancel: false,
    customStyle: true
  })
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    const stateVisible = new DerivedState(() => {
      const linkmicState = this.sdk.linkmicManager.linkmicState.value
      const sdkSupportLinkMic = this.sdk.linkmicManager.sdkSupportChannelLinkMic.value ?? false
      return linkmicState === PLVLinkMicState.Inviting && sdkSupportLinkMic
    })
    stateVisible.observe((isVisible) => {
      if (isVisible) {
        this.invitationDialog.open()
      } else {
        this.invitationDialog.close()
      }
    }).pushTo(this.observers)
  }

  build() {

  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
    this.observers = []
  }
}

@CustomDialog
struct PLVSALinkMicInvitationDialog {
  controller: CustomDialogController = lateInit()
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @State acceptInvitationTimeLeft: number = 0
  private taskUpdateTimeLeft: PLVScheduledTask | undefined = undefined
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    this.startTimeLeftCountDown()
  }

  build() {
    Column() {
      // 连麦邀请铃声
      PLVSALinkMicInvitationSound()

      Text($r('app.string.plvsa_linkmic_invitation_dialog_title'))
        .fontColor('#FFFFFF')
        .fontWeight(FontWeight.Bold)
        .fontSize(18)
        .textAlign(TextAlign.Center)

      Text($r('app.string.plvsa_linkmic_invitation_dialog_content', this.acceptInvitationTimeLeft.toString()))
        .fontColor('#BFFFFFFF')
        .fontSize(14)
        .textAlign(TextAlign.Center)
        .margin({
          top: 12
        })

      Row() {
        Text($r('app.string.plvsa_linkmic_invitation_dialog_refuse'))
          .layoutWeight(1)
          .fontColor('#0382FF')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .textAlign(TextAlign.Center)
          .borderRadius(18)
          .borderColor('#0080FF')
          .borderWidth(1)
          .padding({
            top: 11,
            bottom: 11
          })
          .onClick(() => {
            this.sdk.linkmicManager.refuseLinkMicInvitation()
            this.controller.close()
          })
        Blank()
          .width(10)
        Text($r('app.string.plvsa_linkmic_invitation_dialog_accept'))
          .layoutWeight(1)
          .fontColor('#FFFFFF')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .textAlign(TextAlign.Center)
          .borderRadius(18)
          .linearGradient({
            angle: 90,
            colors: [
              ['#0080FF', 0],
              ['#3399FF', 0]
            ]
          })
          .padding({
            top: 11,
            bottom: 11
          })
          .onClick(() => {
            this.sdk.linkmicManager.acceptLinkMicInvitation()
            this.controller.close()
          })
      }
      .width('100%')
      .margin({
        top: 25
      })
    }
    .width(260)
    .backgroundColor('#2C2C2C')
    .borderRadius(16)
    .padding({
      left: 24,
      right: 24,
      top: 20,
      bottom: 18
    })
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
    this.stopTimeLeftCountDown()
    MutableObserver.disposeAll(this.observers)
    this.observers = []
  }
}

@Component
struct PLVSALinkMicInvitationSound {
  private readonly soundFileName = "plvsa_linkmic_invitation_bgm.mp3"
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