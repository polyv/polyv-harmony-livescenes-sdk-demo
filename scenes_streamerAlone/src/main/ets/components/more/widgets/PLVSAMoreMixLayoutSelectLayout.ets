import { lateInit, MutableObserver } from '@polyvharmony/media-player-sdk';
import { display } from '@kit.ArkUI';
import { PLVLiveSceneSDK, PLVStreamerMixLayoutType } from '@polyvharmony/live-scenes-sdk';

@CustomDialog
export struct PLVSAMoreMixLayoutSelectLayout {
  controller: CustomDialogController = lateInit()

  build() {
    if (this.isPortrait()) {
      PLVSAMoreMixLayoutSelectLayoutPort({
        closeController: () => {
          this.controller.close()
        }
      })
    } else {
      PLVSAMoreMixLayoutSelectLayoutLand({
        closeController: () => {
          this.controller.close()
        }
      })
    }
  }

  private isPortrait(): boolean {
    const orientation = display.getDefaultDisplaySync().orientation
    return orientation === display.Orientation.PORTRAIT || orientation === display.Orientation.PORTRAIT_INVERTED
  }
}

@Component
struct PLVSAMoreMixLayoutSelectLayoutPort {
  closeController: () => void = lateInit()
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @State private currentMixLayoutType: PLVStreamerMixLayoutType = PLVStreamerMixLayoutType.TILE
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    this.sdk.streamerManager.mixLayoutType.observe(it => this.currentMixLayoutType = it)
      .pushTo(this.observers)
  }

  build() {
    Column() {
      Text($r('app.string.plvsa_more_mix_layout_select_title'))
        .fontColor('#F0F1F5')
        .fontSize(18)
        .margin({
          left: 32,
          top: 32
        })

      Row() {
        Text($r('app.string.plvsa_more_mix_layout_type_speaker'))
          .width(88)
          .height(32)
          .textAlign(TextAlign.Center)
          .fontColor('#FFFFFF')
          .fontSize(14)
          .borderRadius(18)
          .linearGradient({
            angle: 90,
            colors: this.isSelected(PLVStreamerMixLayoutType.SPEAKER)
              ? [['#0080FF', 0], ['#3399FF', 1]]
              : [['#33FFFFFF', 0], ['#33FFFFFF', 1]]
          })
          .onClick(() => {
            this.sdk.streamerManager.setMixLayoutType(PLVStreamerMixLayoutType.SPEAKER)
            this.closeController()
          })
        Blank()
        Text($r('app.string.plvsa_more_mix_layout_type_tile'))
          .width(88)
          .height(32)
          .textAlign(TextAlign.Center)
          .fontColor('#FFFFFF')
          .fontSize(14)
          .borderRadius(18)
          .linearGradient({
            angle: 90,
            colors: this.isSelected(PLVStreamerMixLayoutType.TILE)
              ? [['#0080FF', 0], ['#3399FF', 1]]
              : [['#33FFFFFF', 0], ['#33FFFFFF', 1]]
          })
          .onClick(() => {
            this.sdk.streamerManager.setMixLayoutType(PLVStreamerMixLayoutType.TILE)
            this.closeController()
          })
        Blank()
        Text($r('app.string.plvsa_more_mix_layout_type_single'))
          .width(88)
          .height(32)
          .textAlign(TextAlign.Center)
          .fontColor('#FFFFFF')
          .fontSize(14)
          .borderRadius(18)
          .linearGradient({
            angle: 90,
            colors: this.isSelected(PLVStreamerMixLayoutType.SINGLE)
              ? [['#0080FF', 0], ['#3399FF', 1]]
              : [['#33FFFFFF', 0], ['#33FFFFFF', 1]]
          })
          .onClick(() => {
            this.sdk.streamerManager.setMixLayoutType(PLVStreamerMixLayoutType.SINGLE)
            this.closeController()
          })
      }
      .width('100%')
      .padding({
        left: 32,
        right: 32
      })
      .margin({
        top: 32
      })
    }
    .width('100%')
    .height(214)
    .alignItems(HorizontalAlign.Start)
    .backgroundColor('#2c2c2c')
    .borderRadius({
      topLeft: 16,
      topRight: 16
    })

  }

  private isSelected(mixLayoutType: PLVStreamerMixLayoutType): boolean {
    return this.currentMixLayoutType === mixLayoutType
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
    this.observers = []
  }
}

@Component
struct PLVSAMoreMixLayoutSelectLayoutLand {
  closeController: () => void = lateInit()
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @State private currentMixLayoutType: PLVStreamerMixLayoutType = PLVStreamerMixLayoutType.TILE
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    this.sdk.streamerManager.mixLayoutType.observe(it => this.currentMixLayoutType = it)
      .pushTo(this.observers)
  }

  build() {
    Column() {
      Text($r('app.string.plvsa_more_mix_layout_select_title'))
        .fontColor('#F0F1F5')
        .fontSize(18)
        .margin({
          left: 32,
          top: 32
        })

      Column() {
        Text($r('app.string.plvsa_more_mix_layout_type_speaker'))
          .width(88)
          .height(32)
          .textAlign(TextAlign.Center)
          .fontColor('#FFFFFF')
          .fontSize(14)
          .borderRadius(18)
          .linearGradient({
            angle: 90,
            colors: this.isSelected(PLVStreamerMixLayoutType.SPEAKER)
              ? [['#0080FF', 0], ['#3399FF', 1]]
              : [['#33FFFFFF', 0], ['#33FFFFFF', 1]]
          })
          .onClick(() => {
            this.sdk.streamerManager.setMixLayoutType(PLVStreamerMixLayoutType.SPEAKER)
            this.closeController()
          })
        Blank().height(24)
        Text($r('app.string.plvsa_more_mix_layout_type_tile'))
          .width(88)
          .height(32)
          .textAlign(TextAlign.Center)
          .fontColor('#FFFFFF')
          .fontSize(14)
          .borderRadius(18)
          .linearGradient({
            angle: 90,
            colors: this.isSelected(PLVStreamerMixLayoutType.TILE)
              ? [['#0080FF', 0], ['#3399FF', 1]]
              : [['#33FFFFFF', 0], ['#33FFFFFF', 1]]
          })
          .onClick(() => {
            this.sdk.streamerManager.setMixLayoutType(PLVStreamerMixLayoutType.TILE)
            this.closeController()
          })
        Blank().height(24)
        Text($r('app.string.plvsa_more_mix_layout_type_single'))
          .width(88)
          .height(32)
          .textAlign(TextAlign.Center)
          .fontColor('#FFFFFF')
          .fontSize(14)
          .borderRadius(18)
          .linearGradient({
            angle: 90,
            colors: this.isSelected(PLVStreamerMixLayoutType.SINGLE)
              ? [['#0080FF', 0], ['#3399FF', 1]]
              : [['#33FFFFFF', 0], ['#33FFFFFF', 1]]
          })
          .onClick(() => {
            this.sdk.streamerManager.setMixLayoutType(PLVStreamerMixLayoutType.SINGLE)
            this.closeController()
          })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding({
        left: 32,
        right: 32
      })
      .margin({
        top: 32
      })
    }
    .width(214)
    .height('100%')
    .alignItems(HorizontalAlign.Start)
    .backgroundColor('#2c2c2c')
    .borderRadius({
      topLeft: 16,
      bottomLeft: 16
    })

  }

  private isSelected(mixLayoutType: PLVStreamerMixLayoutType): boolean {
    return this.currentMixLayoutType === mixLayoutType
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
    this.observers = []
  }
}