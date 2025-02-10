import { lateInit, MutableObserver } from "@polyvharmony/media-player-sdk";
import { display } from "@kit.ArkUI";
import { PLVLinkMicMode, PLVLiveSceneSDK, PLVUserType } from "@polyvharmony/live-scenes-sdk";
import { PLVSAConfirmDialog } from "../../../common/widget/PLVSAConfirmDialog";

@CustomDialog
export struct PLVSAMoreLinkMicSettingLayout {
  controller: CustomDialogController = lateInit()

  build() {
    PLVSAMoreLinkMicSettingLayoutPort()
  }

  private isPortrait(): boolean {
    const orientation = display.getDefaultDisplaySync().orientation
    return orientation === display.Orientation.PORTRAIT || orientation === display.Orientation.PORTRAIT_INVERTED
  }

}

@Component
struct PLVSAMoreLinkMicSettingLayoutPort {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @State private linkmicMode: PLVLinkMicMode = PLVLinkMicMode.AUDIO
  private hangupViewerBeforeSwitchLinkMicDialog: CustomDialogController | null = null
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    this.sdk.linkmicManager.channelLinkMicMode.observe(it => this.linkmicMode = it).pushTo(this.observers)
  }

  build() {
    Column() {
      Text($r('app.string.plvsa_linkmic_setting_text'))
        .fontSize(18)
        .fontColor('#F0F1F5')

      Text($r('app.string.plvsa_linkmic_setting_default_linkmic_type'))
        .fontSize(12)
        .fontColor('#99F0F1F5')
        .margin({
          top: 32
        })

      Row(){
        Column() {
          Text($r('app.string.plvsa_linkmic_setting_linkmic_type_audio'))
            .fontSize(14)
            .fontColor(this.linkmicMode === PLVLinkMicMode.AUDIO ? '#4399FF' : '#F0F1F5')
          if (this.linkmicMode === PLVLinkMicMode.AUDIO) {
            Circle()
              .width(4)
              .height(4)
              .fill('#4399FF')
              .margin({
                top: 2
              })
          }
        }
        .onClick(() => this.onClickSwitchLinkMicMode(PLVLinkMicMode.AUDIO))

        Column() {
          Text($r('app.string.plvsa_linkmic_setting_linkmic_type_video'))
            .fontSize(14)
            .fontColor(this.linkmicMode === PLVLinkMicMode.VIDEO ? '#4399FF' : '#F0F1F5')
          if (this.linkmicMode === PLVLinkMicMode.VIDEO) {
            Circle()
              .width(4)
              .height(4)
              .fill('#4399FF')
              .margin({
                top: 2
              })
          }
        }
        .margin({
          left: 32
        })
        .onClick(() => this.onClickSwitchLinkMicMode(PLVLinkMicMode.VIDEO))
      }
      .alignItems(VerticalAlign.Top)
      .margin({
        top: 14
      })

      Text($r('app.string.plvsa_linkmic_setting_switch_hint'))
        .fontSize(12)
        .fontColor('#878B93')
        .margin({
          top: 12
        })

      Blank()

      Text($r('app.string.plvsa_linkmic_setting_default_setting_hint'))
        .fontSize(12)
        .fontColor('#99F0F1F5')
    }
    .width('100%')
    .height(426)
    .alignItems(HorizontalAlign.Start)
    .padding({
      top: 32,
      left: 32,
      right: 32,
      bottom: 24
    })
    .backgroundColor('#2C2C2C')
    .borderRadius({
      topLeft: 16,
      topRight: 16
    })
  }

  private onClickSwitchLinkMicMode(mode: PLVLinkMicMode) {
    if (mode === this.linkmicMode) {
      return
    }
    const hasLinkMicViewer = (this.sdk.linkmicManager.channelLinkMicViewers.value ?? [])
      .filter(it => it.viewerType !== PLVUserType.USERTYPE_TEACHER)
      .length > 0
    if (hasLinkMicViewer) {
      this.hangupViewerBeforeSwitchLinkMicDialog = new CustomDialogController({
        builder: PLVSAConfirmDialog({
          content: $r('app.string.plvsa_linkmic_setting_switch_type_hang_up_viewer_dialog_content'),
          confirmText: $r('app.string.plvsa_linkmic_setting_switch_type_hang_up_viewer_dialog_confirm'),
          onClickConfirm: (controller) => {
            this.sdk.linkmicManager.setLinkMicMode(mode)
            controller?.close()
          }
        }),
        customStyle: true
      })
      this.hangupViewerBeforeSwitchLinkMicDialog.open()
    } else {
      this.sdk.linkmicManager.setLinkMicMode(mode)
    }
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
    this.observers = []
  }

}