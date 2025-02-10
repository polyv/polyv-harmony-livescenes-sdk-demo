import { PLVLiveSceneSDK, PLVPushDowngradePreference } from '@polyvharmony/live-scenes-sdk';
import { lateInit, MutableObserver } from '@polyvharmony/media-player-sdk';
import { PLVSAPreferenceCardView } from '../../../common/widget/PLVSAPreferenceCardView';
import { display } from '@kit.ArkUI';

@CustomDialog
export struct PLVSAMorePushDowngradeLayout {
  controller: CustomDialogController = lateInit()

  build() {
    if (this.isPortrait()) {
      PLVSAMorePushDowngradeLayoutPort()
    } else {
      PLVSAMorePushDowngradeLayoutLand()
    }
  }

  private isPortrait(): boolean {
    const orientation = display.getDefaultDisplaySync().orientation
    return orientation === display.Orientation.PORTRAIT || orientation === display.Orientation.PORTRAIT_INVERTED
  }
}

@Component
struct PLVSAMorePushDowngradeLayoutPort {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @State private currentPreference: PLVPushDowngradePreference = PLVPushDowngradePreference.PREFER_BETTER_QUALITY
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    this.sdk.streamerManager.pushDowngradePreference.observe(it => this.currentPreference = it)
      .pushTo(this.observers)
  }

  build() {
    Column() {
      Text($r('app.string.plvsa_push_downgrade_preference_title'))
        .fontColor('#F0F1F5')
        .fontSize(18)
        .margin({
          left: 32,
          top: 32
        })

      PLVSAPreferenceCardView({
        slot: () => {
          this.PreferenceDescriptionColumn(
            $r('app.string.plvsa_push_downgrade_quality_title'),
            $r('app.string.plvsa_push_downgrade_quality_desc')
          )
        },
        selected: this.currentPreference === PLVPushDowngradePreference.PREFER_BETTER_QUALITY
      })
        .onClick(() => {
          this.sdk.streamerManager.setPushDowngradePreference(PLVPushDowngradePreference.PREFER_BETTER_QUALITY)
        })
        .width('calc(100% - 32vp)')
        .margin({
          top: 30,
          left: 16,
          right: 16
        })

      PLVSAPreferenceCardView({
        slot: () => {
          this.PreferenceDescriptionColumn(
            $r('app.string.plvsa_push_downgrade_fluency_title'),
            $r('app.string.plvsa_push_downgrade_fluency_desc')
          )
        },
        selected: this.currentPreference === PLVPushDowngradePreference.PREFER_BETTER_FLUENCY
      })
        .onClick(() => {
          this.sdk.streamerManager.setPushDowngradePreference(PLVPushDowngradePreference.PREFER_BETTER_FLUENCY)
        })
        .width('calc(100% - 32vp)')
        .margin({
          top: 12,
          left: 16,
          right: 16
        })
    }
    .width('100%')
    .height(350)
    .alignItems(HorizontalAlign.Start)
    .backgroundColor('#2c2c2c')
    .borderRadius({
      topLeft: 16,
      topRight: 16
    })
  }

  @Builder
  private PreferenceDescriptionColumn(
    title: Resource,
    desc: Resource
  ) {
    Column() {
      Text(title)
        .fontColor('#F0F1F5')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
      Text(desc)
        .fontColor('#99F0F1F5')
        .fontSize(12)
        .margin({
          top: 4
        })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding({
      top: 12,
      bottom: 12,
      left: 20,
      right: 20
    })
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
    this.observers = []
  }
}

@Component
struct PLVSAMorePushDowngradeLayoutLand {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @State private currentPreference: PLVPushDowngradePreference = PLVPushDowngradePreference.PREFER_BETTER_QUALITY
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    this.sdk.streamerManager.pushDowngradePreference.observe(it => this.currentPreference = it)
      .pushTo(this.observers)
  }

  build() {
    Column() {
      Text($r('app.string.plvsa_push_downgrade_preference_title'))
        .fontColor('#F0F1F5')
        .fontSize(18)
        .margin({
          left: 32,
          top: 32
        })

      PLVSAPreferenceCardView({
        slot: () => {
          this.PreferenceDescriptionColumn(
            $r('app.string.plvsa_push_downgrade_quality_title'),
            $r('app.string.plvsa_push_downgrade_quality_desc')
          )
        },
        selected: this.currentPreference === PLVPushDowngradePreference.PREFER_BETTER_QUALITY
      })
        .onClick(() => {
          this.sdk.streamerManager.setPushDowngradePreference(PLVPushDowngradePreference.PREFER_BETTER_QUALITY)
        })
        .width('calc(100% - 32vp)')
        .margin({
          top: 30,
          left: 16,
          right: 16
        })

      PLVSAPreferenceCardView({
        slot: () => {
          this.PreferenceDescriptionColumn(
            $r('app.string.plvsa_push_downgrade_fluency_title'),
            $r('app.string.plvsa_push_downgrade_fluency_desc')
          )
        },
        selected: this.currentPreference === PLVPushDowngradePreference.PREFER_BETTER_FLUENCY
      })
        .onClick(() => {
          this.sdk.streamerManager.setPushDowngradePreference(PLVPushDowngradePreference.PREFER_BETTER_FLUENCY)
        })
        .width('calc(100% - 32vp)')
        .margin({
          top: 12,
          left: 16,
          right: 16
        })
    }
    .width(300)
    .height('100%')
    .alignItems(HorizontalAlign.Start)
    .backgroundColor('#2c2c2c')
    .borderRadius({
      topLeft: 16,
      bottomLeft: 16
    })
  }

  @Builder
  private PreferenceDescriptionColumn(
    title: Resource,
    desc: Resource
  ) {
    Column() {
      Text(title)
        .fontColor('#F0F1F5')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
      Text(desc)
        .fontColor('#99F0F1F5')
        .fontSize(12)
        .margin({
          top: 4
        })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding({
      top: 12,
      bottom: 12,
      left: 20,
      right: 20
    })
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
    this.observers = []
  }
}