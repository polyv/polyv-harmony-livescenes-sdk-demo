import { PLVCommonConstants, PLVLiveSceneSDK } from '@polyvharmony/live-scenes-sdk';
import { PLVMediaCastDevice } from '@polyvharmony/media-cast';
import { deepEquals, lateInit, MutableObserver, PLVMediaBitRate, watchStates } from '@polyvharmony/media-player-sdk';
import { PLVLWLayoutDataBus } from '../../../../common/PLVLWLayoutDataBus';
import { PLVLWPlayerControllerVariantState } from '../vo/PLVLWPlayerControllerVariantState';
import { PLVLWCastDeviceSelectLayout } from '../widget/PLVLWCastDeviceSelectLayout';
import { PLVLWCastPlayPauseButton } from '../widget/PLVLWCastPlayPauseButton';
import { PLVLWCastStopButton } from '../widget/PLVLWCastStopButton';
import { PLVLWPlayerControllerToggleOrientationButton } from '../widget/PLVLWPlayerControllerToggleOrientationButton';

@Component
export struct PLVLWCastController {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @Consume('layoutDataBus') layoutDataBus: PLVLWLayoutDataBus
  @State private currentCastDevice: PLVMediaCastDevice | undefined = undefined
  @State private supportBitRates: PLVMediaBitRate[] = []
  @State private currentBitRate: PLVMediaBitRate | undefined = undefined
  private readonly deviceSelectDialog = new CustomDialogController({
    builder: PLVLWCastDeviceSelectLayout(),
    alignment: DialogAlignment.BottomEnd,
    customStyle: true
  })
  private readonly switchBitrateDialog = new CustomDialogController({
    builder: PLVLWCastBitRateSelectDialog(),
    alignment: DialogAlignment.BottomEnd,
    customStyle: true
  })
  private observers: MutableObserver[] = []

  static match(variant: PLVLWPlayerControllerVariantState): boolean {
    return variant.isCasting
  }

  aboutToAppear(): void {
    watchStates(() => {
      this.currentCastDevice = this.layoutDataBus.mediaCast.currentCastDevice.value
    }).pushTo(this.observers)
    watchStates(() => {
      const mediaPlayer = this.sdk.playerManager.mainMediaPlayer
      this.supportBitRates = mediaPlayer.getBusinessListenerRegistry().supportMediaBitRates.value ?? []
      this.currentBitRate = this.layoutDataBus.mediaCast.castBitRate.value
    }).pushTo(this.observers)
  }

  build() {
    RelativeContainer() {
      PLVLWCastPlayPauseButton()
        .width(36)
        .height(36)
        .alignRules({
          left: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Start },
          bottom: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Bottom }
        })
        .margin({
          left: 8,
          bottom: 8
        })

      PLVLWPlayerControllerToggleOrientationButton()
        .width(36)
        .height(36)
        .alignRules({
          right: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.End },
          bottom: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Bottom }
        })
        .margin({
          right: 8,
          bottom: 8
        })

      PLVLWCastStopButton()
        .width(36)
        .height(36)
        .alignRules({
          right: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.End },
          top: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Top }
        })
        .margin({
          right: 8,
          top: 8
        })

      Column() {
        Stack() {
          Image($r('app.media.plvlw_cast_status_bg'))
            .width(PLVCommonConstants.FULL_PERCENT)
            .height(PLVCommonConstants.FULL_PERCENT)
            .objectFit(ImageFit.Contain)

          Column() {
            Text(this.currentCastDevice?.friendlyName)
              .fontColor('#FFFFFF')
              .fontSize(16)

            Text($r('app.string.plvlw_cast_connect_device_switch'))
              .fontColor('#CCCCCC')
              .fontSize(12)
              .padding(5)
              .onClick(() => {
                this.deviceSelectDialog.open()
              })
          }
          .alignItems(HorizontalAlign.Center)
        }
        .width(195)
        .height(56)

        if (this.supportBitRates.length > 1 && this.currentBitRate) {
          Text(this.currentBitRate.name)
            .fontColor('#FFFFFF')
            .fontSize(16)
            .padding({
              left: 20,
              right: 20,
              top: 5,
              bottom: 5
            })
            .borderRadius(15)
            .borderColor('#FFFFFF')
            .borderWidth(1)
            .margin({
              top: 20
            })
            .onClick(() => {
              this.switchBitrateDialog.open()
            })
        }
      }
      .alignItems(HorizontalAlign.Center)
      .alignRules({
        center: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Center },
        middle: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Center }
      })
    }
    .width(PLVCommonConstants.FULL_PERCENT)
    .backgroundColor('#000000')
    .onClick(() => {
    })
  }
}

@CustomDialog
struct PLVLWCastBitRateSelectDialog {
  controller: CustomDialogController = lateInit()
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @Consume('layoutDataBus') layoutDataBus: PLVLWLayoutDataBus
  @State private isPortrait: boolean = true
  @State private supportBitRates: PLVMediaBitRate[] = []
  @State private currentBitRate: PLVMediaBitRate | undefined = undefined
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    this.layoutDataBus.isPortrait.observe(it => this.isPortrait = it).pushTo(this.observers)
    watchStates(() => {
      const mediaPlayer = this.sdk.playerManager.mainMediaPlayer
      this.supportBitRates = mediaPlayer.getBusinessListenerRegistry().supportMediaBitRates.value ?? []
      this.currentBitRate = this.layoutDataBus.mediaCast.castBitRate.value
    }).pushTo(this.observers)
  }

  build() {
    RelativeContainer() {
      Text($r('app.string.plvlw_player_definition'))
        .id('plvlw_more_bit_rate_title')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.plvlw_more_setting_action_popup_layout_title'))
        .alignRules({
          middle: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Center },
          top: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Top }
        })
        .margin({
          top: 15
        })

      List({
        space: 8
      }) {
        ForEach(
          this.supportBitRates,
          (bitRate: PLVMediaBitRate) => {
            ListItem() {
              Text(bitRate.name)
                .width(PLVCommonConstants.FULL_PERCENT)
                .height(56)
                .textAlign(TextAlign.Center)
                .fontSize(14)
                .fontColor(deepEquals(bitRate, this.currentBitRate)
                  ? $r('app.color.plvlw_more_setting_action_popup_layout_selected_item_text')
                  : $r('app.color.plvlw_more_setting_action_popup_layout_not_selected_item_text')
                )
                .border({
                  radius: 8,
                  color: deepEquals(bitRate, this.currentBitRate)
                    ? $r('app.color.plvlw_more_setting_action_popup_layout_selected_item_stroke')
                    : $r('app.color.plvlw_more_setting_action_popup_layout_not_selected_item_solid'),
                  width: 1
                })
                .backgroundColor(deepEquals(bitRate, this.currentBitRate)
                  ? $r('app.color.plvlw_more_setting_action_popup_layout_selected_item_solid')
                  : $r('app.color.plvlw_more_setting_action_popup_layout_not_selected_item_solid')
                )
            }
            .onClick(() => {
              if (!deepEquals(bitRate, this.currentBitRate)) {
                this.layoutDataBus.mediaCast.onSwitchBitRate.setValue(bitRate)
                this.controller.close()
              }
            })
          },
          (bitRate: PLVMediaBitRate) => bitRate.index.toString()
        )
      }
      .width(PLVCommonConstants.FULL_PERCENT)
      .padding({
        left: 16,
        right: 16
      })
      .alignRules({
        top: { anchor: 'plvlw_more_bit_rate_title', align: VerticalAlign.Bottom },
        bottom: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Bottom }
      })
      .margin({
        top: 27,
        bottom: 46
      })
    }
    .width(this.isPortrait ? PLVCommonConstants.FULL_PERCENT : 375)
    .height(this.isPortrait ? 294 : PLVCommonConstants.FULL_PERCENT)
    .backgroundColor($r('app.color.plvlw_common_popup_background'))
    .borderRadius({
      topLeft: 16,
      topRight: this.isPortrait ? 16 : 0,
      bottomLeft: this.isPortrait ? 0 : 16
    })
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
  }
}