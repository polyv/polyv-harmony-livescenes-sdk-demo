import { PLVLiveSceneSDK, PLVToastUtils } from '@polyvharmony/live-scenes-sdk'
import { lateInit, MutableObserver } from '@polyvharmony/media-player-sdk'
import { PLVSAConfirmDialog } from '../../../common/widget/PLVSAConfirmDialog'

@Component
export struct PLVSAMoreHangupAllLinkMicButton {
  iconPadding: number = 8
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  private readonly hangupAllLinkMicConfirmDialog = new CustomDialogController({
    builder: PLVSAConfirmDialog({
      content: $r('app.string.plvsa_linkmic_hang_up_all_confirm_content'),
      onClickConfirm: (controller) => {
        this.sdk.linkmicManager.hangupAllViewersLinkMic()
        PLVToastUtils.shortShow($r('app.string.plvsa_linkmic_hang_up_all_toast'))
        controller?.close()
      }
    }),
    customStyle: true
  })
  @State private enable: boolean = true
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    this.sdk.linkmicManager.channelLinkMicViewers.observe(viewers => {
      const hasOtherLinkMicViewer = viewers.some(it => it.linkmicId !== this.sdk.channelData.linkmicId)
      this.enable = hasOtherLinkMicViewer
    }).pushTo(this.observers)
  }

  build() {
    Column() {
      Image($r('app.media.plvsa_more_hang_up_viewer_linkmic_icon'))
        .width(48)
        .height(48)
        .padding(this.iconPadding)
        .objectFit(ImageFit.Contain)
      Text($r('app.string.plvsa_linkmic_hang_up_all_text'))
        .fontColor("#FFFFFF")
        .fontSize(12)
        .textAlign(TextAlign.Center)
    }
    .enabled(this.enable)
    .opacity(this.enable ? 1 : 0.6)
    .onClick(() => {
      this.hangupAllLinkMicConfirmDialog.open()
    })
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
    this.observers = []
  }
}